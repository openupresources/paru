#--
# Copyright 2015, 2016, 2017 Huub de Beer <Huub@heerdebeer.org>
#
# This file is part of Paru
#
# Paru is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Paru is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Paru.  If not, see <http://www.gnu.org/licenses/>.
#++
require_relative "./selector.rb"
require_relative "./filter/document.rb"
require_relative "./filter/metadata.rb"

module Paru
    # Paru filter is a wrapper around pandoc's JSON api, which is based on
    # {pandoc-types}[https://hackage.haskell.org/package/pandoc-types-1.17.0.4/docs/Text-Pandoc-Definition.html].
    # Pandoc treats block elements and inline elements differently.
    #
    # Pandoc's block elements are:
    PANDOC_BLOCK = [
        "Block",
        "Plain",
        "Para",
        "LineBlock",
        "CodeBlock",
        "RawBlock",
        "BlockQuote",
        "OrderedList",
        "BulletList",
        "DefinitionList",
        "Header",
        "HorizontalRule",
        "Table",
        "Div",
        "Null"
    ]

    # Pandoc's inline elements are
    PANDOC_INLINE = [
        "Str",
        "Emph",
        "Strong",
        "Strikeout",
        "Superscript",
        "Subscript",
        "SmallCaps",
        "Quoted",
        "Cite",
        "Code",
        "Space",
        "SoftBreak",
        "LineBreak",
        "Math",
        "RawInline",
        "Link",
        "Image",
        "Note",
        "Span"
    ]

    # All of pandoc's type together:
    PANDOC_TYPES = PANDOC_BLOCK + PANDOC_INLINE


    # Filter is used to write your own pandoc filter in Ruby. A Filter is
    # almost always created and immediately executed via the +run+ method. The
    # most simple filter you can write in paru is the so-called "identity":
    #
    # {include:file:examples/filters/identity.rb}
    #
    # It runs the filter, but it makes no selection nor performs an action.
    # This is pretty useless, of course—although it makes for a great way to
    # test the filter functionality—, but it shows the general setup of a
    # filter well.
    #
    # = Writing a simple filter: numbering figures
    #
    # Inside a {Filter#run} block, you specify *selectors* with *actions*. For
    # example, to number all figures in a document and prefix their captions
    # with "Figure", the following filter would work:
    #
    # {include:file:examples/filters/number_figures.rb}
    #
    # This filter selects all {PandocFilter::Image} nodes. For each
    # {PandocFilter::Image} node it increments the figure counter
    # +figure_counter+ and then sets the figure's caption to "Figure" followed
    # by the figure count and the original caption.  In other words, the
    # following input document
    #
    #     ![My first image](img/horse.png)
    #
    #     ![My second image](img/rabbit.jpeg)
    #
    # will be transformed into
    #
    #     ![Figure 1. My first image](img/horse.png)
    #
    #     ![Figure 2. My second image](img/rabbit.jpeg)
    #
    # The method {PandocFilter::InnerMarkdown#inner_markdown} and its counterpart
    # {PandocFilter::Node#markdown} are a great way to manipulate the
    # contents of a selected {PandocFilter::Node}. No messing about creating
    # and filling {PandocFilter::Node}s, you can just use pandoc's own
    # markdown format!
    #
    # = Writing a more involved filters
    #
    # == Using the "follows" selector: Numbering figures and chapters
    #
    # The previous example can be extended to also number chapters and to
    # start numbering figures anew per chapter. As you would expect, we need
    # two counters, one for the figures and one for the chapters:
    #
    # {include:file:examples/filters/number_figures_per_chapter.rb}
    #
    # What is new in this filter, however, is the selector "Header + Image"
    # which selects all {PandocFilter::Image} nodes that *follow* a
    # {PandocFilter::Header} node. Documents in pandoc have a _flat_ structure
    # where chapters do not exists as separate concepts. Instead, a chapter is
    # implied by a header of a certain level and everything that follows until
    # the next header of that level.
    #
    # == Using the "child of" selector: Annotate custom blocks
    #
    # Hierarchical structures do exist in a pandoc document, however. For
    # example, the contents of a paragraph ({PandocFilter::Para}), which
    # itself is a {PandocFilter::Block} level node, are {PandocFilter::Inline}
    # level nodes. Another example are custom block or {PandocFilter::Div}
    # nodes.  You select a child node by using the +>+ selector as in the
    # example below:
    #
    # {include:file:examples/filters/example.rb}
    #
    # Here all {PandocFilter::Header} nodes that are inside a
    # {PandocFilter::Div} node are selected. Furthermore, if these headers are
    # of level 3, they are prefixed by the string "Example" followed by a
    # count.
    #
    # In this example, "important" {PandocFilter::Div} nodes are annotated by
    # putting the string *important* before the contents of the node.
    #
    # == Using a distance in a selector: Capitalize the first N characters of
    # a paragraph
    #
    # Given the flat structure of a pandoc document, the "follows" selector
    # has quite a reach. For example, "Header + Para" selects all paragraphs
    # that follow a header. In most well-structured documents, this would
    # select basically all paragraphs.
    #
    # But what if you need to be more specific? For example, if you would like
    # to capitalize the first sentence of each first paragraph of a chapter,
    # you need a way to specify a sequence number of sorts. To that end, paru
    # filter selectors take an optional *distance* parameter. A filter for
    # this example could look like:
    #
    # {include:file:examples/filters/capitalize_first_sentence.rb}
    #
    # The distance is denoted after a selector by an integer. In this case
    # "Header +1 Para" selects all {PandocFilter::Para} nodes that directly
    # follow an {PandocFilter::Header} node. You can use a distance with any
    # selector.
    #
    # == Manipulating nodes: Removing horizontal lines
    #
    # Although the {PandocFilter::InnerMarkdown#inner_markdown} and
    # {PandocFilter::Node#markdown} work in most situations, sometimes
    # direct manipulation of the pandoc document AST is useful. These
    # {PandocFilter::ASTManipulation} methods are mixed in
    # {PandocFilter::Node} and can be used on any node in your filter. For
    # example, to delete all {PandocFilter::HorizontalRule} nodes, can use a
    # filter like:
    #
    # {include:file:examples/filters/delete_horizontal_rules.rb}
    #
    # Note that you could have arrived at the same effect by using:
    #
    #     rule.markdown = ""
    #
    # == Manipulating metadata:
    #
    # One of the interesting features of the pandoc markdown format is the
    # ability to add metadata to a document via a YAML block or command line
    # options. For example, if you use a template that uses the metadata
    # property +$date$+ to write a date on a title page, it is quite useful to
    # automatically add the date of _today_ to the metadata. You can do so
    # with a filter like:
    #
    # {include:file:examples/filters/add_today.rb}
    #
    # In a filter, the +metadata+ property is a Ruby Hash of Strings, Numbers,
    # Booleans, Arrays, and Hashes. You can manipulate it like any other Ruby
    # Hash.
    #
    # @!attribute metadata
    #   @return [Hash] The metadata of the document being filtered as a Ruby
    #     Hash
    #
    # @!attribute document
    #   @return [Document] The document being filtered
    #
    # @!attribute current_node
    #   @return [Node] The node in the AST of the document being filtered that
    #      is currently being inspected by the filter.
    #
    class Filter

        attr_reader :metadata, :document, :current_node

        # Create a new Filter instance. For convenience, {run} creates a new
        # {Filter} and runs it immediately. Use this constructor if you want
        # to run a filter on different input and output streams that STDIN and
        # STDOUT respectively.
        #
        # @param input [IO = $stdin] the input stream to read, defaults to
        #   STDIN
        # @param output [IO = $stdout] the output stream to write, defaults to
        #   STDOUT
        def initialize(input = $stdin, output = $stdout)
            @input = input
            @output = output
        end

        # Run the filter specified by block. This is a convenience method that
        # creates a new {Filter} using input stream STDIN and output stream
        # STDOUT and immediately runs {filter} with the block supplied.
        #
        # @param block [Proc] the filter specification
        #
        # @example Add 'Figure' to each image's caption
        #   Paru::Filter.run do
        #       with "Image" do |image|
        #           image.inner_markdown = "Figure. #{image.inner_markdown}"
        #       end
        #   end
        def self.run(&block)
            Filter.new($stdin, $stdout).filter(&block)
        end

        # Create a filter using +block+. In the block you specify
        # selectors and actions to be performed on selected nodes. In the
        # example below, the selector is "Image", which selects all image
        # nodes. The action is to prepend the contents of the image's caption
        # by the string "Figure. ".
        #
        # @param block [Proc] the filter specification
        #
        # @return [JSON] a JSON string with the filtered pandoc AST
        #
        # @example Add 'Figure' to each image's caption
        #   input = IOString.new(File.read("my_report.md")
        #   output = IOString.new
        #
        #   Paru::Filter.new(input, output).filter do
        #       with "Image" do |image|
        #           image.inner_markdown = "Figure. #{image.inner_markdown}"
        #       end
        #   end
        #
        def filter(&block)
            @selectors = Hash.new
            @filtered_nodes = []
            @document = read_document

            @metadata = PandocFilter::Metadata.new @document.meta

            nodes_to_filter = Enumerator.new do |node_list|
                @document.each_depth_first do |node|
                    node_list << node
                end
            end

            @current_node = @document

            nodes_to_filter.each do |node|
                if @current_node.has_been_replaced?
                    @current_node = @current_node.get_replacement
                    @filtered_nodes.pop
                else
                    @current_node = node
                end

                @filtered_nodes.push @current_node

                instance_eval(&block) # run the actual filter code
            end

            write_document
        end

        # Specify what nodes to filter with a +selector+. If the +current_node+
        # matches that selector, it is passed to the block to this +with+ method.
        #
        # @param selector [String] a selector string
        # @yield [Node] the current node if it matches the selector
        def with(selector)
            @selectors[selector] = Selector.new selector unless @selectors.has_key? selector
            yield @current_node if @selectors[selector].matches? @current_node, @filtered_nodes
        end

        # Stop processing the document any further and output it as it is now.
        # This is a great timesaver for filters that only act on a small
        # number of nodes in a large document, or when you only want to set
        # the metadata.
        #
        # Note, stop will break off the filter immediately after outputting
        # the document in its current state.
        def stop!()
            write_document
            exit true
        end


        private

        # The Document node from JSON formatted pandoc document structure
        # on STDIN that is being filtered
        #
        # @return [Document] create a new Document node from a pandoc AST from
        #   JSON from STDIN
        def read_document()
            PandocFilter::Document.from_JSON @input.read
        end

        # Write the document being filtered to STDOUT
        def write_document()
            @document.meta = @metadata.to_meta
            @output.write @document.to_JSON
        end
    end

    # FilterError is thrown when there is an error during filtering
    class FilterError < Error
    end
end
