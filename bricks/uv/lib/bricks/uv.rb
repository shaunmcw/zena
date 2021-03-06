require 'uv'

module Bricks
  module Uv
    module SyntaxMethods
      SYNTAXES = Hash[*::Uv.syntaxes.map{|s| [s,true]}.flatten]

      def to_html(opts = {})
        theme = opts[:theme] || 'idle'
        line_numbers = (opts[:line_numbers] == 'true') && !opts[:inline]
        code_class = "#{theme}_code"

        if SYNTAXES[@code_lang]
          res = ::Uv.parse(@text, 'xhtml', @code_lang, line_numbers, theme)
          if opts[:inline]
            res.gsub(/\A<pre class=.#{theme}.>/,"<code class='#{code_class}'>").gsub(%r{</pre>\Z}, '</code>')
          else
            res.gsub(/\A<pre class=.#{theme}.>/,"<pre class='#{code_class}'>").gsub(%r{</pre>\Z}, '</pre>')
          end
        else
          super
        end
      end
    end # SyntaxMethods
  end # Uv
end # Bricks