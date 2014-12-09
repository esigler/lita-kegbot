module Lita
  module Handlers
    class Kegbot < Handler
      config :api_key, required: true
      config :api_url, required: true

      route(
        /^(?:kegbot|kb)\s(?:drink|drinks)\slist(?<c>\s\d+)?$/,
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

      # rubocop:disable Metrics/AbcSize
      def drink_list(response)
        count = response.match_data['c'] ? response.match_data['c'].to_i : 5
        drinks = fetch_drinks

        return response.reply(t('error.request')) unless drinks
        return response.reply(t('drinks.none')) unless drinks.count > 0

        count.times do |i|
          response.reply(format_drink(drinks[i])) if drinks[i]
        end
      end
      # rubocop:enable Metrics/AbcSize

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
          response.reply(format_keg(keg))
        end
      end

      def keg_status_id(response)
        keg = fetch_keg(response.matches[0][0].to_i)
        return response.reply(t('error.request')) unless keg
        response.reply(format_keg(keg))
      end

      private

      def format_drink(drink)
        formatted_date = drink['session']['start_time']
        beer = drink['keg']['beverage']['name']
        t('drinks.info', user: drink['user_id'],
                         beer: beer,
                         date: formatted_date)
      end

      def format_keg(keg)
        keg['online'] ? status = 'online' : status = 'offline'
        pct = format('%3.2f', keg['percent_full'])
        t('kegs.info', id: keg['id'],
                       beer: keg['beverage']['name'],
                       status: status,
                       pct: pct)
      end

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

      # rubocop:disable Metrics/AbcSize
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
      # rubocop:enable Metrics/AbcSize
    end

    Lita.register_handler(Kegbot)
  end
end
