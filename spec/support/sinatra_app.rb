# frozen_string_literal: true

require 'sinatra/base'
require 'rack/contrib'
require 'sinatra/param'

class SinatraApp < Sinatra::Base
  use BatchApi::RackMiddleware
  use Rack::JSONBodyParser
  helpers Sinatra::Param

  get '/endpoint' do
    headers['GET'] = 'hello'
    # including this in the body would mess the body up
    # due to the other headers inserted
    headers['REQUEST_HEADERS'] = header_output
    content_type :json

    status 422
    {
      result: 'GET OK',
      params: params.except(:endpoint),
    }.to_json
  end

  get '/longboi' do
    sleep 0.3
    headers['GET'] = 'hello'
    # including this in the body would mess the body up
    # due to the other headers inserted
    headers['REQUEST_HEADERS'] = header_output
    content_type :json

    status 422
    {
      result: 'GET OK',
      params: params.except(:endpoint),
    }.to_json
  end

  get '/endpoint/capture/:captured' do
    content_type :json
    { result: params[:captured] }.to_json
  end

  post '/endpoint' do
    headers['POST'] = 'guten tag'
    headers['REQUEST_HEADERS'] = header_output
    content_type :json
    status 203
    {
      result: 'POST OK',
      params: params.except(:endpoint),
    }.to_json
  end

  post '/endpoint/post_param' do
    param :param, String, required: true
    content_type :json
    status 200
    { result: params[:param] }.to_json
  end

  get '/endpoint/error' do
    raise StandardError
  end

  private

  def header_output
    # we only want the headers that were sent by the client
    # headers in sinatra are just read directly from env
    # env has a ton of additional information we don't want
    # and that reference the request itself, causing an infinite loop
    env.inject({}) do |h, (k, v)|
      h.tap { |hash| hash[k.to_s] = v.to_s if k.include?('HTTP_') }
    end
  end
end
