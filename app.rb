# frozen_string_literal: true

require 'sinatra/base'
require 'jbuilder'

class Microblog < Sinatra::Base
  helpers do
    def jbuilder(locals = {})
      Jbuilder.new do |json|
        locals.each { |key, value| json.set! key, value }
        yield json if block_given?
      end.target!
    end
  end

  Dir[File.join(File.dirname(__FILE__), 'controllers', '*.rb')].each(&method(:require))

  run! if app_file == $PROGRAM_NAME
end
