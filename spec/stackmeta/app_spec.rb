# frozen_string_literal: true

describe Stackmeta::App do
  before :each do
    allow_any_instance_of(Stackmeta::Finder)
      .to receive(:find).with(stack: 'wat').and_return(stack_summary)
    allow_any_instance_of(Stackmeta::Finder)
      .to receive(:find_item).with(stack: 'wat', item: 'thing')
                             .and_return(thing_bytes)
  end

  let :stack_summary do
    {
      name: 'wat',
      items: {
        'thing' => 'wat/thang',
        'lol' => 'wat/lol'
      }
    }
  end

  let :thing_bytes do
    'spooooooOOOOOOookyyyyy'
  end

  describe 'GET /' do
    it 'returns 200' do
      response = get '/'
      expect(response.status).to eq(200)
    end

    it 'is friendly' do
      response = get '/'
      body = MultiJson.load(response.body)
      expect(body).to include('greeting')
      expect(body['greeting']).to be =~ /hello/
    end
  end

  describe 'GET /:stack' do
    it 'returns 200' do
      response = get '/wat'
      expect(response.status).to eq(200)
    end

    it 'responds with a stack' do
      response = get '/wat'
      body = MultiJson.load(response.body)
      expect(body).to include('stack')
      expect(body['stack']).to_not be_nil
      expect(body).to include('@requested_stack')
      expect(body['@requested_stack']).to eq('wat')
    end

    context 'when stack is not found' do
      before do
        allow_any_instance_of(Stackmeta::Finder)
          .to receive(:find).with(stack: 'wat').and_return(nil)
      end

      it 'returns 404' do
        response = get '/wat'
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'GET /:stack/:item' do
    it 'returns 200' do
      response = get '/wat/thing'
      expect(response.status).to eq(200)
    end

    it 'responds with an item' do
      response = get '/wat/thing'
      body = MultiJson.load(response.body)
      expect(body).to include('item')
      expect(body['item']).to_not be_nil
      expect(body).to include('@encoding')
      expect(body['@encoding']).to eq('base64')
      expect(body).to include('@requested_stack')
      expect(body['@requested_stack']).to eq('wat')
      expect(body).to include('@requested_item')
      expect(body['@requested_item']).to eq('thing')
    end
  end
end
