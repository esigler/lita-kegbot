module Lita
  module Handlers
    class Kegbot < Handler
      config :api_key, required: true
      config :api_url, required: true

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

      def drink_list(response)
        count_match = response.matches[0][0]
        count_match ? count = count_match.to_i : count = 5
        current = 0
        drinks = fetch_drinks

        return response.reply(t('error.request')) unless drinks
        return response.reply(t('drinks.none')) unless drinks.count > 0

        drinks.each do |drink|
          next if current >= count
          formatted_date = drink['session']['start_time']
          beer = drink['keg']['beverage']['name']
          response.reply(t('drinks.info', user: drink['user_id'],
                                          beer: beer,
                                          date: formatted_date))
          current += 1
        end
      end

      def tap_status_all(response)
        taps = fetch_taps
        return response.reply(t('error.request')) unless taps
        return response.reply(t('taps.none')) unless taps.count > 0
        taps.each do |tap|
          response.reply(t('taps.info', id: tap['id'], name: tap['name']))
        end
      end

      def tap_status_id(response)
        tap = fetch_tap(response.matches[0][0].to_i)
        return response.reply(t('error.request')) unless tap
        response.reply(t('taps.info', id: tap['id'], name: tap['name']))
      end

      def keg_status_all(response)
        kegs = fetch_kegs
        return response.reply(t('error.request')) unless kegs
        return response.reply(t('kegs.none')) unless kegs.count > 0
        kegs.each do |keg|
          next unless keg['online']
          keg['online'] ? status = 'online' : status = 'offline'
          pct = format('%3.2f', keg['percent_full'])
          response.reply(t('kegs.info', id: keg['id'],
                                        beer: keg['beverage']['name'],
                                        status: status,
                                        pct: pct))
        end
      end

      def keg_status_id(response)
        keg = fetch_keg(response.matches[0][0].to_i)
        return response.reply(t('error.request')) unless keg

        keg['online'] ? status = 'online' : status = 'offline'
        pct = format('%3.2f', keg['percent_full'])
        response.reply(t('kegs.info', id: keg['id'],
                                      beer: keg['beverage']['name'],
                                      status: status,
                                      pct: pct))
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
        http_response = http.send(method) do |req|
          req.url "#{config.api_url}/api/#{path}", args
          req.headers['X-Kegbot-Api-Key'] = config.api_key
        end

        unless http_response.status == 200 || http_response.status == 201
          log.error("#{method}:#{path}:#{args}:#{http_response.status}")
          return nil
        end

        MultiJson.load(http_response.body)
      end
    end

    Lita.register_handler(Kegbot)
  end
end
