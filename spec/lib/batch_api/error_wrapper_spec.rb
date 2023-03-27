# frozen_string_literal: true

require 'spec_helper'
require 'batch_api/error_wrapper'

describe BatchApi::ErrorWrapper do
  let(:exception) do
    StandardError.new(Faker::Lorem.words.join).tap do |e|
      e.set_backtrace(Kernel.caller)
    end
  end

  let(:error) { described_class.new(exception) }

  describe '#body' do
    it 'includes the message in the body' do
      expect(error.body[:error][:message]).to eq(exception.message)
    end

    it 'includes the backtrace if it should be there' do
      allow(error).to receive(:expose_backtrace?).and_return(true)
      expect(error.body[:error][:backtrace]).to eq(exception.backtrace)
    end

    it 'does not include the backtrace if it should not be there' do
      allow(error).to receive(:expose_backtrace?).and_return(false)
      expect(error.body[:backtrace]).to be_nil
    end
  end

  describe '#render' do
    it 'returns the appropriate status' do
      status = double
      allow(error).to receive(:status_code).and_return(status)
      expect(error.render[0]).to eq(status)
    end

    it 'returns appropriate content type' do
      ctype = double
      allow(BatchApi::RackMiddleware).to receive(:content_type).and_return(ctype)
      expect(error.render[1]).to eq(ctype)
    end

    it 'returns the JSONified body as the 2nd' do
      expect(error.render[2]).to eq([MultiJson.dump(error.body)])
    end
  end

  describe '#status_code' do
    it 'returns 500 by default' do
      expect(error.status_code).to eq(500)
    end

    it 'returns another status code if the error supports that' do
      err = StandardError.new
      code = double
      allow(err).to receive(:status_code).and_return(code)
      expect(described_class.new(err).status_code).to eq(code)
    end
  end

  describe '.expose_backtrace?' do
    it "returns false if ENV['RACK_ENV'] == 'production'" do
      ENV['RACK_ENV'] = 'production'
      expect(described_class).not_to be_expose_backtrace

      ENV['RACK_ENV'] = 'test'
      expect(described_class).to be_expose_backtrace
    end
  end
end
