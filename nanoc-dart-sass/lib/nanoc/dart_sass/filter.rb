# frozen_string_literal: true

module Nanoc
  module DartSass
    class Filter < Nanoc::Filter
      identifier :dart_sass

      # Runs the content through [Dart Sass](https://sass-lang.com/dart-sass).
      # Parameters passed as `:args` will be passed on to Dart Sass.
      #
      # @param [String] content The content to filter
      #
      # @return [String] The filtered content
      def run(content, params = {})
        # Read syntax
        syntax = params[:syntax]
        syntax ||= Util.syntax_from_ext(item.identifier.ext)

        result = Sass.compile_string(
          content,
          importer: NanocImporter.new(@items, item),
          **params,
          syntax: syntax,
        )
        result.css
      end

      class NanocImporter
        def initialize(items, source_item)
          @items = items
          @source_item = source_item
        end

        def canonicalize(url, *, **)
          # Construct proper URL with `nanoc:` prefix if needed
          if url.start_with?('nanoc:')
            url
          else
            "nanoc:#{url}"
          end
        end

        def load(url)
          item = find_item_for_url(url)

          {
            contents: item.raw_content,
            syntax: Util.syntax_from_ext(item.identifier.ext),
          }
        end

        private

        def find_item_for_url(url)
          pat = url.sub(/\Ananoc:/, '')

          is_extension_given = !pat.match?(%r{(/|^)[^.]+$})

          # Convert to absolute pattern
          pat =
            if pat.start_with?('/')
              pat
            else
              dirname = File.dirname(@source_item.identifier.to_s)
              File.expand_path(pat, dirname)
            end

          items = []

          # Try as a regular path
          items << try_pat(pat, is_extension_given)

          # Try as a partial
          partial_pat = File.join(File.dirname(pat), "_#{File.basename(pat)}")
          items << try_pat(partial_pat, is_extension_given)

          # Try as index
          unless is_extension_given
            items << @items[File.join(pat, '/index.*')]
            items << @items[File.join(pat, '/_index.*')]
          end

          items = items.compact
          case items.size
          when 0
            raise "Could not find an item matching pattern `#{pat}`"
          when 1
            items.first
          else
            raise "It is not clear which item to import. Multiple items match `#{pat}`: #{items.map { _1.identifier.to_s }.join(', ')}"
          end
        end

        def try_pat(pat, is_extension_given)
          if is_extension_given
            @items[pat]
          else
            @items["#{pat}.*"]
          end
        end
      end

      module Util
        module_function

        def syntax_from_ext(ext)
          case ext
          when 'sass'
            :indented
          when 'scss'
            :scss
          when 'css'
            :css
          else
            nil
          end
        end
      end

      private_constant :Util
    end
  end
end
