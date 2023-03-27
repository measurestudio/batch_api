# frozen_string_literal: true

require 'spec_helper'
require 'support/sinatra_app'
require 'rack/test'

describe SinatraApp do
  include Rack::Test::Methods

  def app
    SinatraApp
  end

  def headerize(hash)
    hash.to_h do |k, v|
      ["HTTP_#{k.to_s.upcase}", v.to_s]
    end
  end

  before do
    BatchApi.config.endpoint = '/batch'
    BatchApi.config.verb = :post
    allow(BatchApi::ErrorWrapper).to receive(:expose_backtrace?).and_return(false)
  end

  context 'when issued a get request' do
    describe 'with an explicit get' do
      before do

        post '/batch', {
          ops: [{ url: '/endpoint', method: 'GET', headers: { 'foo' => 'bar' }, params: { 'other' => 'value' } }],
          sequential: true,
        }.to_json, 'CONTENT_TYPE' => 'application/json'

      end

      it 'returns the body as objects' do
        result = JSON.parse(last_response.body)['results'][0]
        expect(result['body']).to eq({
          'result' => 'GET OK',
          'params' => { 'other' => 'value' },
        })
      end

      it 'returns the expected status' do
        result = JSON.parse(last_response.body)['results'][0]
        expect(result['status']).to eq(422)
      end

      it 'returns the expected headers' do
        result = JSON.parse(last_response.body)['results'][0]
        expect(result['headers']).to include({ 'GET' => 'hello' })
      end

      it 'verifies that the right headers were received' do
        result = JSON.parse(last_response.body)['results'][0]
        expect(result['headers']['REQUEST_HEADERS']).to include(headerize({ 'FOO' => 'bar' }))
      end
    end

    describe 'with no method' do
      before do
        post '/batch', {
          ops: [{ url: '/endpoint', headers: { 'foo' => 'bar' }, params: { 'other' => 'value' } }],
          sequential: true,
        }.to_json, 'CONTENT_TYPE' => 'application/json'
      end

      it 'returns the body as objects' do
        result = JSON.parse(last_response.body)['results'][0]
        expect(result['body']).to eq({
          'result' => 'GET OK',
          'params' => { 'other' => 'value' },
        })
      end

      it 'returns the expected status' do
        result = JSON.parse(last_response.body)['results'][0]
        expect(result['status']).to eq(422)
      end

      it 'returns the expected headers' do
        result = JSON.parse(last_response.body)['results'][0]
        expect(result['headers']).to include({ 'GET' => 'hello' })
      end

      it 'verifies that the right headers were received' do
        result = JSON.parse(last_response.body)['results'][0]
        expect(result['headers']['REQUEST_HEADERS']).to include(headerize({ 'FOO' => 'bar' }))
      end
    end
  end

  context 'when issued a post request' do
    before do

      post '/batch', {
        ops: [
          {
            url: '/endpoint',
            method: 'POST',
            headers: { 'POST' => 'guten tag' },
            params: { 'other' => 'value' },
          },
        ],
        sequential: true,
      }.to_json, 'CONTENT_TYPE' => 'application/json'

    end

    describe 'the response' do
      it 'returns the body as objects (since DecodeJsonBody is default)' do
        expect(JSON.parse(last_response.body)['results'][0]['body']).to eq({
          'result' => 'POST OK',
          'params' => { 'other' => 'value' },
        })
      end

      it 'returns the expected status' do
        expect(JSON.parse(last_response.body)['results'][0]['status']).to eq(203)
      end

      it 'returns the expected headers' do
        expect(JSON.parse(last_response.body)['results'][0]['headers']).to include({ 'POST' => 'guten tag' })
      end

      it 'verifies that the right headers were received' do
        expect(JSON.parse(last_response.body)['results'][0]['headers']['REQUEST_HEADERS']).to include(
          headerize({ 'POST' => 'guten tag' })
        )
      end
    end
  end

  context 'when issued a request that results in a server error' do
    before do
      post '/batch', {
        ops: [
          {
            url: '/endpoint/error',
            method: 'GET',
          },
        ],
        sequential: true,
      }.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'returns the right status' do
      expect(JSON.parse(last_response.body)['results'][0]['status']).to eq(500)
    end

    it 'returns the right error information' do
      expect(JSON.parse(last_response.body)['results'][0]['body']['error']).to include(
        { 'message' => 'StandardError' }
      )
    end
  end

  context 'when issued a request resulting in a not found error' do
    before do
      post '/batch', {
        ops: [
          {
            url: '/very/missing/such/wow',
            method: 'DELETE',
          },
        ],
        sequential: true,
      }.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'returns the right status' do
      expect(JSON.parse(last_response.body)['results'][0]['status']).to eq(404)
    end
  end

  context 'when issued a silent request' do
    before do
      post '/batch', {
        ops: [
          {
            url: '/endpoint',
            method: 'POST',
            silent: true,
          },
        ],
        sequential: true,
      }.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'returns nothing' do
      expect(JSON.parse(last_response.body)['results'][0]).to eq({})
    end
  end

  context 'when issued a silent request that causes an error' do
    before do
      post '/batch', {
        ops: [
          {
            url: '/very/missing/such/wow',
            method: 'DELETE',
            silent: true,
          },
        ],
        sequential: true,
      }.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    it 'returns a regular result' do
      expect(JSON.parse(last_response.body)['results'][0].keys).not_to be_empty
    end
  end
end
