module Lita
  module Handlers
    class Kegbot < Handler
      route(
        /^(?:kegbot|kb)\sdrink\slist$/,
        :drink_list_all,
        command: true,
        help: {
          t('help.drink_list.syntax') => t('help.drink_list.desc')
        }
      )

      route(
        /^(?:kegbot|kb)\sdrink\slist\s(\d+)$/,
        :drink_list,
        command: true,
        help: {
          t('help.drink_list_N.syntax') => t('help.drink_list_N.desc')
        }
      )

      route(
        /^(?:kegbot|kb)\stap\sstatus$/,
        :tap_status_all,
        command: true,
        help: {
          t('help.tap_status.syntax') => t('help.tap_status.desc')
        }
      )

      route(
        /^(?:kegbot|kb)\stap\sstatus\s(\d+)$/,
        :tap_status_id,
        command: true,
        help: {
          t('help.tap_status_id.syntax') => t('help.tap_status_id.desc')
        }
      )

      route(
        /^(?:kegbot|kb)\skeg\sstatus$/,
        :keg_status_all,
        command: true,
        help: {
          t('help.keg_status.syntax') => t('help.keg_status.desc')
        }
      )

      route(
        /^(?:kegbot|kb)\skeg\sstatus\s(\d+)$/,
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

      def drink_list_all(response)
        result = api_request('get', 'drinks/')
        if result && result['objects']
          drinks = result['objects']
          response.reply(t('drinks.none')) unless drinks.count > 0
          drinks.each do |drink|
            session = drink['session']
            response.reply(t('drinks.info', user: drink['user_id'],
                                            date: session['start_time']))
          end
        else
          response.reply(t('error.request'))
        end
      end

      def drink_list(response)
        count = response.matches[0][0].to_i
        current = 0
        result = api_request('get', 'drinks')
        if result && result['result'] && result['result']['drinks']
          drinks = result['result']['drinks']
          response.reply(t('drinks.none')) unless drinks.count > 0
          drinks.each do |drink|
            if current < count
              response.reply(t('drinks.info', user: drink['user_id'],
                                              date: drink['pour_time']))
              current += 1
            end
          end
        else
          response.reply(t('error.request'))
        end
      end

      def tap_status_all(response)
        result = api_request('get', 'taps/')
        if result && result['objects']
          taps = result['objects']
          response.reply(t('taps.none')) unless taps.count > 0
          taps.each do |tap|
            response.reply(t('taps.info', id: tap['id'], name: tap['name']))
          end
        else
          response.reply(t('error.request'))
        end
      end

      def tap_status_id(response)
        id = response.matches[0][0].to_i
        result = api_request('get', "taps/#{id}")
        if result && result['object']
          tap = result['object']
          response.reply(t('taps.info', id: tap['id'], name: tap['name']))
        else
          response.reply(t('error.request'))
        end
      end

      def keg_status_all(response)
        result = api_request('get', 'kegs/')
        if result && result['objects']
          kegs = result['objects']
          response.reply(t('kegs.none')) unless kegs.count > 0
          kegs.each do |keg|
            keg['status'] ? status = 'offline' : status = 'online'
            response.reply(t('kegs.info', id: keg['id'],
                                          beer: keg['beverage']['name'],
                                          status: status,
                                          pct: keg['percent_full']))
          end
        else
          response.reply(t('error.request'))
        end
      end

      def keg_status_id(response)
        id = response.matches[0][0].to_i
        result = api_request('get', "kegs/#{id}")
        if result && result['object']
          keg = result['object']
          keg['status'] ? status = 'offline' : status = 'online'
          response.reply(t('kegs.info', id: keg['id'],
                                        beer: keg['beverage']['name'],
                                        status: status,
                                        pct: keg['percent_full']))
        else
          response.reply(t('error.request'))
        end
      end

      private

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
