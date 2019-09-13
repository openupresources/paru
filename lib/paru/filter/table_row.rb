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
require_relative "./block.rb"

module Paru
    module PandocFilter
        # A TableRow node represents a row in a table's head or body
        class TableRow < Block
            # Create a new TableRow based on the row_data
            #
            # @param row_data [Array]
            def initialize(row_data)
                super []
                row_data.each do |cell|
                    child = Block.new cell
                    child.parent = self
                    @children.push child
                end
            end

            # The AST contents of this TableRow
            #
            # @return [Array]
            def ast_contents
                @children.map {|child| child.ast_contents}
            end

            # Convert this TableRow to an array of markdown strings, one for
            # each cell
            #
            # @return [String[]] An Array representation of this TableRow.
            def to_array()
                @children.map do |cell|
                    cell.children.map{|c| c.markdown.strip}.join("\n")
                end
            end
        end
    end
end
