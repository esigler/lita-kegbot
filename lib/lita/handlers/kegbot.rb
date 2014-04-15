module Lita
  module Handlers
    class Kegbot < Handler
      route(
        /^(?:kegbot|kb)\s(?:drink|drinks)\slist(\s\d+)*$/,
        :drink_list,
        command: true,
        help: {
          t('help.drink_list.syntax') => t('help.drink_list.desc')
        }
      )

      route(
        /^(?:kegbot|kb)\s(?:tap|taps)\sstatus$/,
        :tap_status_all,
        command: true,
        help: {
          t('help.tap_status.syntax') => t('help.tap_status.desc')
        }
      )

      route(
        /^(?:kegbot|kb)\s(?:tap|taps)\sstatus\s(\d+)$/,
        :tap_status_id,
        command: true,
        help: {
          t('help.tap_status_id.syntax') => t('help.tap_status_id.desc')
        }
      )

      route(
        /^(?:kegbot|kb)\s(?:keg|kegs)\sstatus$/,
        :keg_status_all,
        command: true,
        help: {
          t('help.keg_status.syntax') => t('help.keg_status.desc')
        }
      )

      route(
        /^(?:kegbot|kb)\s(?:keg|kegs)\sstatus\s(\d+)$/,
        :keg_status_id,
        command: true,
        help: {
          t('help.keg_status_id.syntax') => t('help.keg_status_id.desc')
        }
      )

      def self.default_config(config)
        config.api_key = nil
        config.api_url = nil
      end

      def drink_list(response)
        count_match = response.matches[0][0]
        count_match ? count = count_match.to_i : count = 5
        current = 0
        drinks = fetch_drinks
        if drinks
          response.reply(t('drinks.none')) unless drinks.count > 0
          drinks.each do |drink|
            if current < count
              formatted_date = drink['session']['start_time']
              beer = drink['keg']['beverage']['name']
              response.reply(t('drinks.info', user: drink['user_id'],
                                              beer: beer,
                                              date: formatted_date))
              current += 1
            end
          end
        else
          response.reply(t('error.request'))
        end
      end

      def tap_status_all(response)
        taps = fetch_taps
        if taps
          response.reply(t('taps.none')) unless taps.count > 0
          taps.each do |tap|
            response.reply(t('taps.info', id: tap['id'], name: tap['name']))
          end
        else
          response.reply(t('error.request'))
        end
      end

      def tap_status_id(response)
        tap = fetch_tap(response.matches[0][0].to_i)
        if tap
          response.reply(t('taps.info', id: tap['id'], name: tap['name']))
        else
          response.reply(t('error.request'))
        end
      end

      def keg_status_all(response)
        kegs = fetch_kegs
        if kegs
          response.reply(t('kegs.none')) unless kegs.count > 0
          kegs.each do |keg|
            if keg['online']
              keg['online'] ? status = 'online' : status = 'offline'
              pct = format('%3.2f', keg['percent_full'])
              response.reply(t('kegs.info', id: keg['id'],
                                            beer: keg['beverage']['name'],
                                            status: status,
                                            pct: pct))
            end
          end
        else
          response.reply(t('error.request'))
        end
      end

      def keg_status_id(response)
        keg = fetch_keg(response.matches[0][0].to_i)
        if keg
          keg['online'] ? status = 'online' : status = 'offline'
          pct = format('%3.2f', keg['percent_full'])
          response.reply(t('kegs.info', id: keg['id'],
                                        beer: keg['beverage']['name'],
                                        status: status,
                                        pct: pct))
        else
          response.reply(t('error.request'))
        end
      end

      private

      def fetch_drinks
        result = api_request('get', 'drinks/')
        result['objects'] if result && result['objects']
      end

      def fetch_tap(id)
        result = api_request('get', "taps/#{id}")
        result['object'] if result && result['object']
      end

      def fetch_taps
        result = api_request('get', 'taps/')
        result['objects'] if result && result['objects']
      end

      def fetch_keg(id)
        result = api_request('get', "kegs/#{id}")
        result['object'] if result && result['object']
      end

      def fetch_kegs
        result = api_request('get', 'kegs/')
        result['objects'] if result && result['objects']
      end

      def api_request(method, path, args = {})
        if Lita.config.handlers.kegbot.api_key.nil? ||
           Lita.config.handlers.kegbot.api_url.nil?
          Lita.logger.error('Missing API key or Page ID for Kegbot')
          fail 'Missing config'
        end

        url = "#{Lita.config.handlers.kegbot.api_url}/api/#{path}"

        http_response = http.send(method) do |req|
          req.url url, args
          req.headers['X-Kegbot-Api-Key'] = \
            Lita.config.handlers.kegbot.api_key
        end

        if http_response.status == 200 ||
           http_response.status == 201
          MultiJson.load(http_response.body)
        else
          Lita.logger.error("HTTP #{method} for #{url} with #{args} " \
                            "returned #{http_response.status}")
          Lita.logger.error(http_response.body)
          nil
        end
      end
    end

    Lita.register_handler(Kegbot)
  end
end
