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
require_relative "./inline.rb"
require_relative "./citation.rb"

module Paru
    module PandocFilter
        # A Cite node, consisting of a list of Citation nodes, and a list of
        # Inline nodes
        #
        # @!attribute citations
        #   @return [Array<Citation>]
        class Cite < Inline
            attr_accessor :citations

            # Create a new Cite node
            #
            # @param contents [Array] an array containing a list of citations
            #   and a list of inline nodes
            def initialize(contents)
                super contents[1]
                @citations = []
                contents[0].each do |citation|
                    @citations.push Citation.new(citation)
                end
            end

            # Create an AST representation of this Cite node.
            def ast_contents()
                [
                    @citations.map {|citation| citation.to_ast},
                    super
                ]
            end

            #undef_method :inner_markdown
            #undef_method :inner_markdown=
        end
    end
end

