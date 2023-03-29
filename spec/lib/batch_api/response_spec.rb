# frozen_string_literal: true

require 'spec_helper'
require 'batch_api/response'

describe BatchApi::Response do

  let(:raw_response) { [200, {}, %w[ab cd ef]] }
  let(:response) { described_class.new(raw_response) }

  %i[status body headers].each do |attr|
    local_attr = attr
    it "has an accessor for #{local_attr}" do
      expect(response).to respond_to(local_attr)
    end
  end

  describe '#initialize' do
    it 'sets status to the HTTP status code' do
      expect(response.status).to eq(raw_response.first)
    end

    it 'sets body to the HTTP body turned into a string' do
      expect(response.body).to eq(raw_response[2].join)
    end

    it 'sets headers to the HTTP headers' do
      expect(response.headers).to eq(raw_response[1])
    end
  end

  describe '#to_h' do
    it 'creates the expected hash' do
      expect(response.to_h).to eq({
        body: response.body,
        status: response.status,
        headers: response.headers,
      })
    end

    it 'accepts options' do
      expect(response.to_h(foo: :bar)).not_to be_nil
    end

    it 'leaves out items that are blank' do
      response.status = response.body = nil
      expect(response.to_h).to eq({ headers: raw_response[1] })
    end

    it 'includes items that are false' do
      response.body = false
      expect(response.to_h[:body]).to be(false)
    end
  end
end
