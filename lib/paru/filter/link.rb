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
require_relative "./attr.rb"
require_relative "./target.rb"

module Paru
    module PandocFilter
        # A Link node has an attribute object, an Inline description and a
        # target
        #
        # @!attribute attr
        #   @return [Attr]
        #
        # @!attribute target
        #   @return [Target]
        class Link < Inline
            attr_accessor :attr, :target

            # Create a new Link node with contents
            #
            # @param contents [Array] an array with attributes, description,
            #   and target information
            def initialize(contents)
                @attr = Attr.new contents[0]
                super contents[1]
                @target = Target.new contents[2]
            end

            # Create an AST representation of this Link node
            def ast_contents
                [
                    @attr.to_ast,
                    super,
                    @target.to_ast
                ]
            end

        end
    end
end
