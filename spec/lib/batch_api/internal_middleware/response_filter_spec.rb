# frozen_string_literal: true

require 'spec_helper'

describe BatchApi::InternalMiddleware::ResponseFilter do
  let(:app) { instance_double(Sinatra::Base, call: result) }
  let(:surpressor) { described_class.new(app) }
  let(:env) do
    {
      op: instance_double(BatchApi::Operation::Rack, options: { 'silent' => true }),
    }
  end

  let(:result) do
    BatchApi::Response.new([
      200,
      { 'Content-Type' => 'application/json' },
      ['{}'],
    ])
  end

  describe '#call' do
    context 'with results with silent' do
      context 'with successful (200-299) results' do
        it 'empties the response so its as_json is empty' do
          surpressor.call(env)
          expect(result.as_json).to eq({})
        end
      end

      context 'with non-successful responses' do
        it "doesn't change anything else" do
          result.status = 301
          expect do
            surpressor.call(env)
          end.not_to change(result, :to_s)
        end
      end
    end

    context 'with results without silent' do
      before do
        env[:op].options[:silent] = nil
      end

      context 'with successful (200-299) results' do
        it 'does nothing' do
          expect do
            surpressor.call(env)
          end.not_to change(result, :to_s)
        end
      end

      context 'with non-successful responses' do
        it "doesn't change anything else" do
          result.status = 301
          expect do
            surpressor.call(env)
          end.not_to change(result, :to_s)
        end
      end
    end
  end
end
