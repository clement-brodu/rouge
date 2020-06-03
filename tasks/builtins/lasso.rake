# -*- coding: utf-8 -*- #
# frozen_string_literal: true

require 'open-uri'

LASSO_SYNTAX_URI = "https://raw.githubusercontent.com/LassoSoft/Lasso-HTML.mode/master/Contents/Resources/SyntaxDefinition.xml"
LASSO_KEYWORDS_FILE = "./lib/rouge/lexers/lasso/keywords.rb"

namespace :builtins do
  task :lasso do
    generator = Rouge::Tasks::Builtins::Lasso.new

    input    = URI.open(LASSO_SYNTAX_URI) { |f| f.read }
    keywords = generator.extract_keywords(input)

    output = generator.render_output(keywords)

    File.write(LASSO_KEYWORDS_FILE, output)
  end
end

module Rouge
  module Tasks
    module Builtins
      class Lasso
        def extract_keywords(input)
          groups = {"Types" => :types,
                    "Traits" => :traits,
                    "Lasso 8 Tags" => :builtins,
                    "Unbound Methods" => :builtins,
                    "Keywords" => :keywords,
                    "Error Keywords" => :exceptions}

          keywords = Hash.new { |h,k| h[k] = Array.new }

          input.scan(%r[<keywords id="(.*?)" .*?>(.*?)</keywords>]m) do |m|
            next unless groups.keys.include? m[0]

            values = m[1].split(/\s*<\/?string>\s*/).
                          reject { |v| v.match(/^\s*$/) }.
                          map { |v| v.strip.downcase }

            keywords[groups[m[0]]].concat values
          end

          keywords
        end

        def render_output (keywords, &b)
          return enum_for(:render_output, keywords).to_a.join("\n") unless b

          yield   "# -*- coding: utf-8 -*- #"
          yield   "# frozen_string_literal: true"
          yield   ""
          yield   "# DO NOT EDIT"
          yield   "# This file is automatically generated by `rake builtins:lasso`."
          yield   "# See tasks/builtins/lasso.rake for more info."
          yield   ""
          yield   "module Rouge"
          yield   "  module Lexers"
          yield   "    def Lasso.keywords"
          yield   "      @keywords ||= {}.tap do |h|"
          keywords.each do |key, value|
            yield "        h[#{key.inspect}] = Set.new #{value.inspect}"
          end
          yield   "      end"
          yield   "    end"
          yield   "  end"
          yield   "end"
        end
      end
    end
  end
end