# frozen_string_literal: true

require 'spec_helper'

describe BatchApi::InternalMiddleware::DecodeJsonBody do
  let(:app) { instance_double(Sinatra::Base, call: result) }
  let(:decoder) { described_class.new(app) }
  let(:env) { {} }
  let(:json) { { 'data' => 'is_json', 'more' => { 'hi' => 'there' } } }
  let(:result) do
    BatchApi::Response.new([
      200,
      { 'Content-Type' => 'application/json' },
      [MultiJson.dump(json)],
    ])
  end

  describe '#call' do
    context 'with json results' do
      it 'decodes JSON results for application/json responses' do
        result = decoder.call(env)
        expect(result.body).to eq(json)
      end

      it "doesn't change anything else" do
        result = decoder.call(env)
        expect(result.status).to eq(200)
        expect(result.headers).to eq({ 'Content-Type' => 'application/json' })
      end
    end

    context 'with non-JSON responses' do
      it "doesn't decode" do
        result.headers = { 'Content-Type' => 'text/html' }
        expect(decoder.call(env).body).to eq(MultiJson.dump(json))
      end
    end

    context 'with empty responses' do
      it "doesn't try to parse" do
        result.body = ''
        expect(decoder.call(env).body).to eq('')
      end
    end
  end
end
