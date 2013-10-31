# encoding: UTF-8

module StandaloneTypograf #:nodoc:
  module Quotes
    extend ActiveSupport::Concern

    Q = '"' # source quote

    CHARS = {
        :outer_left => {html: '&laquo;', utf: '«'},
        :outer_right => {html: '&raquo;', utf: '»'},
        :inner_left => {html: '&bdquo;', utf: '„'},
        :inner_right => {html: '&ldquo;', utf: '“'},
    }.freeze

    included do
      register_processor(Processor)
    end

    # global locks
    LOCK = {
        inside:     false, # inside outer quotes
        outer_open: false, # outer quote opens but not still closed
        inner_open: false, # inner quote opens but not still closed
    }

    class Processor
      attr_reader :text, :mode, :tarr

      def self.compile(text, mode)
        compiler = self.new(text, mode)
        compiler.compile
        text = compiler.tarr.join()
      end

      def initialize(text, mode)
        @text = text
        @mode = mode
        @tarr = text.split(//) # TODO comment
      end

      def lock
        @lock ||= LOCK.deep_dup
      end

      def compile
        tarr.each_with_index do |symbol, index|
          next unless symbol == Q

          if outside? && open_quote?(index)
            tarr[index] = CHARS[:outer_left][mode]
            outer_open_lock!
            next
          end

          if inside? && close_quote?(index)
            tarr[index] = CHARS[:outer_right][mode]
            outer_open_unlock!
            next
          end


        end
      end

      private

      # @return [Boolean]
      # If this quote is open
      def open_quote?(index)
        return true if index == 0
        (text[index-1] =~ /\s/) && (text[index+1] =~ /[[:alpha:]]/)
      end

      # @return [Boolean]
      # If this quote is close
      def close_quote?(index)
        return true if index == (@tarr.length-1)
        (text[index-1] =~ /[[:alpha:]]/) && (text[index+1] =~ /\s/)
      end

      # @return [Boolean]
      # If we outside of outer quotes
      def outside?
        !lock[:outer_open] && !lock[:inside]
      end

      # @return [Boolean]
      # If we inside of outer quotes
      def inside?
        !outside?
      end

      def outer_open_lock!
        lock[:inside]     = true
        lock[:outer_open] = true
      end

      def outer_open_unlock!
        lock[:inside]     = false
        lock[:outer_open] = false
      end
    end
  end
end
