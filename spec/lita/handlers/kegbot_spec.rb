require 'spec_helper'

describe Lita::Handlers::Kegbot, lita_handler: true do
  let(:drinks) do
    File.read('spec/files/drinks.json')
  end

  let(:drinks_empty) do
    File.read('spec/files/drinks_empty.json')
  end

  let(:taps) do
    File.read('spec/files/taps.json')
  end

  let(:taps_empty) do
    File.read('spec/files/taps_empty.json')
  end

  let(:tap) do
    File.read('spec/files/tap.json')
  end

  let(:kegs) do
    File.read('spec/files/kegs.json')
  end

  let(:kegs_empty) do
    File.read('spec/files/kegs_empty.json')
  end

  let(:keg) do
    File.read('spec/files/keg.json')
  end

  %w(kegbot kb).each do |name|
    it do
      is_expected.to route_command("#{name} drink list").to(:drink_list)
      is_expected.to route_command("#{name} drink list 10").to(:drink_list)
      is_expected.to route_command("#{name} tap status").to(:tap_status_all)
      is_expected.to route_command("#{name} tap status 1").to(:tap_status_id)
      is_expected.to route_command("#{name} keg status").to(:keg_status_all)
      is_expected.to route_command("#{name} keg status 1").to(:keg_status_id)
    end
  end

  def grab_request(method, status, body)
    response = double('Faraday::Response', status: status, body: body)
    expect_any_instance_of(Faraday::Connection).to \
      receive(method.to_sym).and_return(response)
  end

  describe 'without valid config' do
    before do
      Lita.config.handlers.kegbot.api_key = nil
      Lita.config.handlers.kegbot.api_url = nil
    end

    describe '.default_config' do
      it 'sets api_key to nil' do
        expect(Lita.config.handlers.kegbot.api_key).to be_nil
      end

      it 'sets api_url to nil' do
        expect(Lita.config.handlers.kegbot.api_url).to be_nil
      end
    end

    it 'should error out on any command' do
      expect { send_command('kb tap status') }.to raise_error('Missing config')
    end
  end

  before do
    Lita.config.handlers.kegbot.api_key = 'foo'
    Lita.config.handlers.kegbot.api_url = 'https://example.com'
  end

  describe '#drink_list' do
    it 'shows a list of drinks if there are any' do
      grab_request('get', 200, drinks)
      send_command('kegbot drink list')
      expect(replies.last).to eq('esigler poured a refreshing glass of ' \
                                 'Racer 5 at 2014-04-14T07:39:01+00:00')
    end

    it 'shows the correct number of drinks if there are that many' do
      grab_request('get', 200, drinks)
      send_command('kegbot drink list 1')
      expect(replies.count).to eq(1)
    end

    it 'shows an empty list if there arent any' do
      grab_request('get', 200, drinks_empty)
      send_command('kegbot drink list')
      expect(replies.last).to eq('No drinks have been poured')
    end

    it 'shows an error if there was a problem with the request' do
      grab_request('get', 500, nil)
      send_command('kegbot drink list 2')
      expect(replies.last).to eq('There was a problem with the Kegbot request')
    end
  end

  describe '#tap_status_all' do
    it 'shows the status of all of the taps if there are any' do
      grab_request('get', 200, taps)
      send_command('kegbot tap status')
      expect(replies.last).to eq('Tap #2: Second Tap')
    end

    it 'shows an empty list if there arent any' do
      grab_request('get', 200, taps_empty)
      send_command('kegbot tap status')
      expect(replies.last).to eq('No taps have been configured')
    end

    it 'shows an error if there was a problem with the request' do
      grab_request('get', 500, nil)
      send_command('kegbot tap status')
      expect(replies.last).to eq('There was a problem with the Kegbot request')
    end
  end

  describe '#tap_status_id' do
    it 'shows the status of a specific tap' do
      grab_request('get', 200, tap)
      send_command('kegbot tap status 1')
      expect(replies.last).to eq('Tap #1: Main Tap')
    end

    it 'shows a warning if that tap does not exist' do
      grab_request('get', 404, nil)
      send_command('kegbot tap status 1')
      expect(replies.last).to eq('There was a problem with the Kegbot request')
    end

    it 'shows an error if there was a problem with the request' do
      grab_request('get', 500, nil)
      send_command('kegbot tap status 1')
      expect(replies.last).to eq('There was a problem with the Kegbot request')
    end
  end

  describe '#keg_status_all' do
    it 'shows the status of all of the kegs if there are any' do
      grab_request('get', 200, kegs)
      send_command('kegbot keg status')
      expect(replies.last).to eq('Keg #1: Racer 5, status: online, 100.00% ' \
                                 'remaining')
    end

    it 'shows an empty list if there arent any' do
      grab_request('get', 200, kegs_empty)
      send_command('kegbot keg status')
      expect(replies.last).to eq('No kegs have been configured')
    end

    it 'shows an error if there was a problem with the request' do
      grab_request('get', 500, nil)
      send_command('kegbot keg status')
      expect(replies.last).to eq('There was a problem with the Kegbot request')
    end
  end

  describe '#keg_status_id' do
    it 'shows the status of a specific keg' do
      grab_request('get', 200, keg)
      send_command('kegbot keg status 1')
      expect(replies.last).to eq('Keg #1: Racer 5, status: online, 100.00% ' \
                                 'remaining')
    end

    it 'shows a warning if that keg does not exist' do
      grab_request('get', 404, nil)
      send_command('kegbot keg status 1')
      expect(replies.last).to eq('There was a problem with the Kegbot request')
    end

    it 'shows an error if there was a problem with the request' do
      grab_request('get', 500, nil)
      send_command('kegbot keg status 1')
      expect(replies.last).to eq('There was a problem with the Kegbot request')
    end
  end
end
