# encoding: utf-8
module Infoboxer
  describe Node do
    describe '#to_tree' do
      let(:plain){node.to_tree}
      let(:indented){node.to_tree(2)}

      subject{plain}

      # Basics ---------------------------------------------------------
      context Text do
        let(:node){Text.new('test')}

        specify{
          expect(plain).to eq "test <Text>\n"
          expect(indented).to eq "    test <Text>\n"
        }
      end

      context Compound do
        let(:node){Compound.new([Text.new('one'), Text.new('two')])}

        specify{
          expect(plain).to eq "<Compound>\n  one <Text>\n  two <Text>\n"
          expect(indented).to eq \
            "    <Compound>\n"\
            "      one <Text>\n"\
            "      two <Text>\n"
        }

        context 'when only one text node' do
          let(:node){Compound.new([Text.new('one')])}

          it{should == "one <Compound>\n"}
        end
      end

      # Inline nodes ---------------------------------------------------
      context Wikilink do
        let(:node){Wikilink.new('Argentina', [Text.new('Argentinian Republic')])}

        it{should ==
          "Argentinian Republic <Wikilink(link: \"Argentina\")>\n"
        }
      end

      context Image do
        context 'without caption' do
          let(:node){Image.new('picture.jpg', width: '5', height: '6')}

          it{should ==
            "<Image(path: \"picture.jpg\", width: \"5\", height: \"6\")>\n"
          }
        end

        context 'with caption' do
          let(:node){
            Image.new('picture.jpg', width: '5', height: '6', caption: [Text.new('Look at me')])
          }

          it{should ==
            "<Image(path: \"picture.jpg\", width: \"5\", height: \"6\")>\n"\
            "  caption:\n"\
            "    Look at me <Text>\n"
          }
        end
      end

      context HTMLTag do
        let(:node){
          HTMLTag.new('div',
            {class: 'table_inside', style: 'float:left;'},
            [Text.new('contents')])
        }

        it{should ==
          "contents <HTMLTag:div(class: \"table_inside\", style: \"float:left;\")>\n"
        }
      end

      context HTMLOpeningTag do
        let(:node){
          HTMLOpeningTag.new('div', {class: 'table_inside', style: 'float:left;'})
        }

        it{should ==
          "<HTMLOpeningTag:div(class: \"table_inside\", style: \"float:left;\")>\n"
        }
      end

      context HTMLClosingTag do
        let(:node){
          HTMLClosingTag.new('div')
        }

        it{should == "<HTMLClosingTag:div>\n"}
      end

      # Paragraph-level nodes ------------------------------------------
      context Heading do
        let(:node){
          Heading.new([Text.new('one')], 3)
        }

        it{should ==
          "one <Heading(level: 3)>\n"
        }
      end

      context List do
        let(:node){
          Parser.parse(%Q{
          * one
          * two
          *# two-1 ''italic''
          *# two-2
          *#; two-2-dt
          *#: two-2-dd
          }.strip.gsub(/\n\s+/m, "\n")).children.first
        }

        it{should ==
          "<UnorderedList>\n"\
          "  one <ListItem>\n"\
          "  <ListItem>\n"\
          "    two <Text>\n"\
          "    <OrderedList>\n"\
          "      <ListItem>\n"\
          "        two-1  <Text>\n"\
          "        italic <Italic>\n"\
          "      <ListItem>\n"\
          "        two-2 <Text>\n"\
          "        <DefinitionList>\n"\
          "          two-2-dt <DTerm>\n"\
          "          two-2-dd <DDefinition>\n"\
        }
      end

      context Template do
        let(:node){
          Parser::InlineParser.parse(%Q{
          {{name|unnamed value|named=named value ''with markup''}}
          }.strip.gsub(/\n\s+/m, "\n")).first
        }

        it{should ==
          "<Template(name)>\n"\
          "  1:\n"\
          "    unnamed value <Text>\n"\
          "  named:\n"\
          "    named value  <Text>\n"\
          "    with markup <Italic>\n"\
        }
      end
    end

    describe '#to_text' do
    end

    describe '#inspect' do
      subject{node.inspect}
      
      context Text do
        context 'by default' do
          let(:node){Text.new('some text')}
          
          it{should == '#<Text: some text>'}
        end

        context 'really long text' do
          let(:str){'some text'*100}
          let(:node){Text.new(str)}
          
          it{should == "#<Text: #{str[0..30]}...>"}
        end
      end
    end
  end
end
