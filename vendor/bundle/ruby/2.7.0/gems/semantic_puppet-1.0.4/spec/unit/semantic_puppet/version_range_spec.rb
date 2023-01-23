require 'spec_helper'
require 'semantic_puppet/version'

describe SemanticPuppet::VersionRange do

  describe '.parse' do
    def self.test_expressions(expressions)
      expressions.each do |range, vs|
        test_range(range, vs[:to_str], vs[:includes], vs[:excludes])
      end
    end

    def self.test_range(range_list, str, includes, excludes)
      Array(range_list).each do |expr|
        example "#{expr.inspect} stringifies as #{str}" do
          range = SemanticPuppet::VersionRange.parse(expr)
          expect(range.inspect).to eql str
        end

        includes.each do |vstring|
          example "#{expr.inspect} includes #{vstring}" do
            range = SemanticPuppet::VersionRange.parse(expr)
            expect(range).to cover(SemanticPuppet::Version.parse(vstring))
          end

          example "parse(#{expr.inspect}).to_s includes #{vstring}" do
            range = SemanticPuppet::VersionRange.parse(expr)
            range = SemanticPuppet::VersionRange.parse(range.to_s)
            expect(range).to cover(SemanticPuppet::Version.parse(vstring))
          end
        end

        excludes.each do |vstring|
          example "#{expr.inspect} excludes #{vstring}" do
            range = SemanticPuppet::VersionRange.parse(expr)
            expect(range).to_not cover(SemanticPuppet::Version.parse(vstring))
          end

          example "parse(#{expr.inspect}).to_s excludes #{vstring}" do
            range = SemanticPuppet::VersionRange.parse(expr)
            range = SemanticPuppet::VersionRange.parse(range.to_s)
            expect(range).to_not cover(SemanticPuppet::Version.parse(vstring))
          end
        end
      end
    end

    context 'loose version expressions' do
      test_expressions(
        [ '1.2.3-alpha' ] => {
          :to_str   => '1.2.3-alpha',
          :includes => [ '1.2.3-alpha'  ],
          :excludes => [ '1.2.3-999', '1.2.3-beta' ],
        },
        [ '1.2.3' ] => {
          :to_str   => '1.2.3',
          :includes => [ '1.2.3' ],
          :excludes => [ '1.2.2', '1.2.3-alpha', '1.2.4-alpha' ],
        },
        [ '1.2', '1.2.x', '1.2.X' ] => {
          :to_str   => '>=1.2.0 <1.3.0',
          :includes => [ '1.2.0', '1.2.999' ],
          :excludes => [ '1.1.999', '1.2.0-alpha', '1.3.0-0' ],
        },
        [ '1', '1.x', '1.X' ] => {
          :to_str   => '>=1.0.0 <2.0.0',
          :includes => [ '1.0.0', '1.999.0' ],
          :excludes => [ '0.999.999', '1.0.0-alpha', '2.0.0-0' ],
        },
      )
    end

    context 'open-ended expressions' do
      test_expressions(
        [ '>1.2.3', '> 1.2.3' ] => {
          :to_str   => '>1.2.3',
          :includes => [ '999.0.0' ],
          :excludes => [ '1.2.3', '1.2.4-0' ],
        },
        [ '>1.2.3-alpha', '> 1.2.3-alpha' ] => {
          :to_str   => '>1.2.3-alpha',
          :includes => [ '1.2.3-alpha.0', '1.2.3-alpha0', '999.0.0' ],
          :excludes => [ '1.2.3-alpha' ],
        },

        [ '>=1.2.3', '>= 1.2.3' ] => {
          :to_str   => '>=1.2.3',
          :includes => [ '999.0.0' ],
          :excludes => [ '1.2.2', '1.2.3-0' ],
        },
        [ '>=1.2.3-alpha', '>= 1.2.3-alpha' ] => {
          :to_str   => '>=1.2.3-alpha',
          :includes => [ '1.2.3-alpha', '1.2.3-alpha0', '999.0.0' ],
          :excludes => [ '1.2.3-alph', '1.2.4-alpha' ],
        },

        [ '<1.2.3', '< 1.2.3' ] => {
          :to_str   => '<1.2.3',
          :includes => [ '0.0.0', '1.2.2' ],
          :excludes => [ '0.0.0-0', '1.2.3-0', '2.0.0' ],
        },
        [ '<1.2.3-alpha', '< 1.2.3-alpha' ] => {
          :to_str   => '<1.2.3-alpha',
          :includes => [ '0.0.0', '1.2.3-alph' ],
          :excludes => [ '0.0.0-0', '1.2.3-alpha', '2.0.0' ],
        },

        [ '<=1.2.3', '<= 1.2.3' ] => {
          :to_str   => '<=1.2.3',
          :includes => [ '0.0.0', '1.2.3' ],
          :excludes => [ '0.0.0-0', '1.2.3-0' ],
        },
        [ '<=1.2.3-alpha', '<= 1.2.3-alpha' ] => {
          :to_str   => '<=1.2.3-alpha',
          :includes => [ '0.0.0', '1.2.3-alpha' ],
          :excludes => [ '0.0.0-0', '1.2.3-alpha0', '1.2.3-alpha.0', '1.2.3-alpha'.next ],
        },
      )
    end

    context '"reasonably close" expressions' do
      test_expressions(
        [ '~ 1', '~1' ] => {
          :to_str   => '>=1.0.0 <2.0.0',
          :includes => [ '1.0.0', '1.999.999' ],
          :excludes => [ '0.999.999', '1.0.0-0', '2.0.0-0' ],
        },
        [ '~ 1.2', '~1.2' ] => {
          :to_str   => '>=1.2.0 <1.3.0',
          :includes => [ '1.2.0', '1.2.999' ],
          :excludes => [ '1.1.999', '1.2.0-0', '1.3.0-0' ],
        },
        [ '~ 1.2.3', '~1.2.3' ] => {
          :to_str   => '>=1.2.3 <1.3.0',
          :includes => [ '1.2.3', '1.2.5' ],
          :excludes => [ '1.2.2', '1.2.3-0', '1.3.0-0' ],
        },
        [ '~ 1.2.3-alpha', '~1.2.3-alpha' ] => {
          :to_str   => '>=1.2.3-alpha <1.3.0',
          :includes => [ '1.2.3-alpha', '1.2.3' ],
          :excludes => [ '1.2.3-alph', '1.2.4-0' ],
        },
      )
    end

    context 'inclusive range expressions' do
      test_expressions(
        '1.2.3 - 1.3.4' => {
          :to_str   => '>=1.2.3 <=1.3.4',
          :includes => [ '1.2.3', '1.3.4' ],
          :excludes => [ '1.2.2', '1.2.3-0', '1.3.5-0' ],
        },
        '1.2.3 - 1.3.4-alpha' => {
          :to_str   => '>=1.2.3 <=1.3.4-alpha',
          :includes => [ '1.2.3', '1.3.4-alpha' ],
          :excludes => [ '1.2.2', '1.2.3-0', '1.3.4-alpha0', '1.3.5' ],
        },

        '1.2.3-alpha - 1.3.4' => {
          :to_str   => '>=1.2.3-alpha <=1.3.4',
          :includes => [ '1.2.3-alpha', '1.3.4' ],
          :excludes => [ '1.2.3-alph', '1.3.5-0' ],
        },
        '1.2.3-alpha - 1.3.4-alpha' => {
          :to_str   => '>=1.2.3-alpha <=1.3.4-alpha',
          :includes => [ '1.2.3-alpha', '1.3.4-alpha' ],
          :excludes => [ '1.2.3-alph', '1.3.4-alpha0', '1.3.5' ],
        },
      )
    end

    context 'unioned expressions' do
      test_expressions(
        [ '1.2 <1.2.5' ] => {
          :to_str   => '>=1.2.0 <1.2.5',
          :includes => [ '1.2.0', '1.2.4' ],
          :excludes => [ '1.1.999', '1.2.0-0', '1.2.5-0', '1.9.0' ],
        },
        [ '1 <=1.2.5' ] => {
          :to_str   => '>=1.0.0 <=1.2.5',
          :includes => [ '1.0.0', '1.2.5' ],
          :excludes => [ '0.999.999', '1.0.0-0', '1.2.6-0', '1.9.0' ],
        },
        [ '>1.0.0 >2.0.0 >=3.0.0 <5.0.0' ] => {
          :to_str   => '>=3.0.0 <5.0.0',
          :includes => [ '3.0.0', '4.999.999' ],
          :excludes => [ '2.999.999', '3.0.0-0', '5.0.0-0' ],
        },
        [ '<1.0.0 >2.0.0' ] => {
          :to_str   => '<0.0.0',
          :includes => [  ],
          :excludes => [ '0.0.0-0', '0.0.0' ],
        },
      )
    end

    context 'ored expressions' do
      context 'overlapping' do
        test_expressions(
          [ '>=1.2.3 || 1.2.5' ] => {
            :to_str   => '>=1.2.3',
            :includes => [ '1.2.3', '1.2.4' ],
            :excludes => [ '1.2.3-0', '1.2.4-0' ],
          },
          [ '>=1.2.3 <=1.2.5 || >=1.2.5 <1.3.0' ] => {
            :to_str   => '>=1.2.3 <1.3.0',
            :includes => [ '1.2.3', '1.2.6' ],
            :excludes => [ '1.2.3-0', '1.2.6-0' ],
          },
        )
      end

      context 'adjacent' do
        test_expressions(
          [ '1.2.3 || 1.2.4 || 1.2.5' ] => {
            :to_str   => '>=1.2.3 <=1.2.5',
            :includes => [ '1.2.3', '1.2.5' ],
            :excludes => [ '1.2.3-0', '1.2.5-0' ],
          },
          [ '>=1.2.3 <1.2.5 || >=1.2.5 <1.3.0' ] => {
            :to_str   => '>=1.2.3 <1.3.0',
            :includes => [ '1.2.3', '1.2.6' ],
            :excludes => [ '1.2.3-0', '1.2.6-0' ],
          },
        )

        let(:range) { SemanticPuppet::VersionRange.parse('>=1.2.3 <1.2.5 || >=1.2.5 <1.3.0') }

        it 'returns expected begin' do
          expect(range.begin.to_s).to eql('1.2.3')
        end

        it 'returns nil on end' do
          expect(range.end.to_s).to eql('1.3.0')
        end

        it 'returns nil on exclude_begin?' do
          expect(range.exclude_begin?).to be_falsey
        end

        it 'returns nil on exclude_end?' do
          expect(range.exclude_end?).to be_truthy
        end
      end

      context 'non-overlapping' do
        test_expressions(
          [ '1.2.3 || 1.2.5' ] => {
            :to_str   => '1.2.3 || 1.2.5',
            :includes => [ '1.2.3', '1.2.5' ],
            :excludes => [ '1.2.4', '1.2.3-0', '1.2.5-0' ],
          },
        )

        let(:range) { SemanticPuppet::VersionRange.parse('1.2.3 || 1.2.5') }

        it 'returns nil on begin' do
          expect(range.begin).to be_nil
        end

        it 'returns nil on end' do
          expect(range.end).to be_nil
        end

        it 'returns nil on exclude_begin?' do
          expect(range.exclude_begin?).to be_nil
        end

        it 'returns nil on exclude_end?' do
          expect(range.exclude_end?).to be_nil
        end
      end
    end

    context 'invalid expressions' do
      example 'raise an appropriate exception' do
        ex = [ ArgumentError, 'Unparsable version range: "invalid"' ]
        expect { SemanticPuppet::VersionRange.parse('invalid') }.to raise_error(*ex)
      end
    end
  end

  describe '#intersection' do
    def self.v(num)
      SemanticPuppet::Version.parse("#{num}.0.0")
    end

    def self.range(x, y, ex = false)
      SemanticPuppet::VersionRange.new(v(x), v(y), ex)
    end

    EMPTY_RANGE = SemanticPuppet::VersionRange::EMPTY_RANGE

    tests = {
      # This falls entirely before the target range
      range(1, 4) => [ EMPTY_RANGE ],

      # This falls entirely after the target range
      range(11, 15) => [ EMPTY_RANGE ],

      # This overlaps the beginning of the target range
      range(1, 6) => [ range(5, 6) ],

      # This overlaps the end of the target range
      range(9, 15) => [ range(9, 10), range(9, 10, true) ],

      # This shares the first value of the target range
      range(1, 5) => [ range(5, 5) ],

      # This shares the last value of the target range
      range(10, 15)  => [ range(10, 10), EMPTY_RANGE ],

      # This shares both values with the target range
      range(5, 10) => [ range(5, 10), range(5, 10, true) ],

      # This is a superset of the target range
      range(4, 11) => [ range(5, 10), range(5, 10, true) ],

      # This is a subset of the target range
      range(6, 9) => [ range(6, 9) ],

      # This shares the first value of the target range, but excludes it
      range(1, 5, true)   => [ EMPTY_RANGE ],

      # This overlaps the beginning of the target range, with an excluded end
      range(1, 7, true)   => [ range(5, 7, true) ],

      # This shares both values with the target range, and excludes the end
      range(5, 10, true)  => [ range(5, 10, true) ],
    }

    inclusive = range(5, 10)
    context "between #{inclusive} &" do
      tests.each do |subject, result|
        result = result.first

        example subject do
          expect(inclusive & subject).to eql(result)
        end
      end
    end

    exclusive = range(5, 10, true)
    context "between #{exclusive} &" do
      tests.each do |subject, result|
        result = result.last

        example subject do
          expect(exclusive & subject).to eql(result)
        end
      end
    end

    context 'is commutative' do
      tests.each do |subject, _|
        example "between #{inclusive} & #{subject}" do
          expect(inclusive & subject).to eql(subject & inclusive)
        end
        example "between #{exclusive} & #{subject}" do
          expect(exclusive & subject).to eql(subject & exclusive)
        end
      end
    end

    it 'cannot intersect with non-VersionRanges' do
      msg = "value must be a SemanticPuppet::VersionRange"
      expect { inclusive.intersection(1..2) }.to raise_error(msg)
    end
  end

  context 'The version' do
    def below(version, range)
      version = SemanticPuppet::Version.parse(version)
      range = SemanticPuppet::VersionRange.parse(range)
      !range.include?(version) && range.ranges.all? { |part| part.exclude_begin? ? part.begin >= version : part.begin > version }
    end

    def above(version, range)
      version = SemanticPuppet::Version.parse(version)
      range = SemanticPuppet::VersionRange.parse(range)
      !range.include?(version) && range.ranges.all? { |part| part.exclude_end? ? part.end <= version.to_stable : part.end < version.to_stable }
    end

    [
      ['~1.2.2', '1.3.0'],
      ['~0.6.1-1', '0.7.1-1'],
      ['1.0.0 - 2.0.0', '2.0.1'],
      ['1.0.0', '1.0.1-beta1'],
      ['1.0.0', '2.0.0'],
      ['<=2.0.0', '2.1.1'],
      ['<=2.0.0', '3.2.9'],
      ['<2.0.0', '2.0.0'],
      ['0.1.20 || 1.2.4', '1.2.5'],
      ['2.x.x', '3.0.0'],
      ['1.2.x', '1.3.0'],
      ['1.2.x || 2.x', '3.0.0'],
      ['2.*.*', '5.0.1'],
      ['1.2.*', '1.3.3'],
      ['1.2.* || 2.*', '4.0.0'],
      ['2', '3.0.0'],
      ['2.3', '2.4.2'],
      ['~2.4', '2.5.0'], # >=2.4.0 <2.5.0
      ['~2.4', '2.5.5'],
      ['~>3.2.1', '3.3.0'], # >=3.2.1 <3.3.0
      ['~1', '2.2.3'], # >=1.0.0 <2.0.0
      ['~>1', '2.2.4'],
      ['~> 1', '3.2.3'],
      ['~1.0', '1.1.2'], # >=1.0.0 <1.1.0
      ['~ 1.0', '1.1.0'],
      ['<1.2', '1.2.0'],
      ['< 1.2', '1.2.1'],
      ['1', '2.0.0-beta'],
      ['~v0.5.4-pre', '0.6.0'],
      ['~v0.5.4-pre', '0.6.1-pre'],
      ['=0.7.x', '0.8.0'],
      ['=0.7.x', '0.8.0-asdf'],
      ['<0.7.x', '0.7.0'],
      ['~1.2.2', '1.3.0'],
      ['1.0.0 - 2.0.0', '2.2.3'],
      ['1.0.0', '1.0.1'],
      ['<=2.0.0', '3.0.0'],
      ['<=2.0.0', '2.9999.9999'],
      ['<=2.0.0', '2.2.9'],
      ['<2.0.0', '2.9999.9999'],
      ['<2.0.0', '2.2.9'],
      ['2.x.x', '3.1.3'],
      ['1.2.x', '1.3.3'],
      ['1.2.x || 2.x', '3.1.3'],
      ['2.*.*', '3.1.3'],
      ['1.2.*', '1.3.3'],
      ['1.2.* || 2.*', '3.1.3'],
      ['2', '3.1.2'],
      ['2.3', '2.4.1'],
      ['~2.4', '2.5.0'], # >=2.4.0 <2.5.0
      ['~>3.2.1', '3.3.2'], # >=3.2.1 <3.3.0
      ['~1', '2.2.3'], # >=1.0.0 <2.0.0
      ['~>1', '2.2.3'],
      ['~1.0', '1.1.0'], # >=1.0.0 <1.1.0
      ['<1', '1.0.0'],
      ['1', '2.0.0-beta'],
      ['<1', '1.0.0-beta'],
      ['< 1', '1.0.0-beta'],
      ['=0.7.x', '0.8.2'],
      ['<0.7.x', '0.7.2']
    ].each do |tuple|
      it "#{tuple[1]} should be above range #{tuple[0]}" do
        expect(above(tuple[1], tuple[0])).to be_truthy
      end
    end

    [
      ['~0.6.1-1', '0.6.1-1'],
      ['1.0.0 - 2.0.0', '1.2.3'],
      ['1.0.0 - 2.0.0', '0.9.9'],
      ['1.0.0', '1.0.0'],
      ['>=*', '0.2.4'],
      ['', '1.0.0'],
      ['*', '1.2.3'],
      ['*', '1.2.3-foo'],
      ['>=1.0.0', '1.0.0'],
      ['>=1.0.0', '1.0.1'],
      ['>=1.0.0', '1.1.0'],
      ['>1.0.0', '1.0.1'],
      ['>1.0.0', '1.1.0'],
      ['<=2.0.0', '2.0.0'],
      ['<=2.0.0', '1.9999.9999'],
      ['<=2.0.0', '0.2.9'],
      ['<2.0.0', '1.9999.9999'],
      ['<2.0.0', '0.2.9'],
      ['>= 1.0.0', '1.0.0'],
      ['>=  1.0.0', '1.0.1'],
      ['>=   1.0.0', '1.1.0'],
      ['> 1.0.0', '1.0.1'],
      ['>  1.0.0', '1.1.0'],
      ['<=   2.0.0', '2.0.0'],
      ['<= 2.0.0', '1.9999.9999'],
      ['<=  2.0.0', '0.2.9'],
      ['<    2.0.0', '1.9999.9999'],
      ["<\t2.0.0", '0.2.9'],
      ['>=0.1.97', '0.1.97'],
      ['>=0.1.97', '0.1.97'],
      ['0.1.20 || 1.2.4', '1.2.4'],
      ['0.1.20 || >1.2.4', '1.2.4'],
      ['0.1.20 || 1.2.4', '1.2.3'],
      ['0.1.20 || 1.2.4', '0.1.20'],
      ['>=0.2.3 || <0.0.1', '0.0.0'],
      ['>=0.2.3 || <0.0.1', '0.2.3'],
      ['>=0.2.3 || <0.0.1', '0.2.4'],
      ['||', '1.3.4'],
      ['2.x.x', '2.1.3'],
      ['1.2.x', '1.2.3'],
      ['1.2.x || 2.x', '2.1.3'],
      ['1.2.x || 2.x', '1.2.3'],
      ['x', '1.2.3'],
      ['2.*.*', '2.1.3'],
      ['1.2.*', '1.2.3'],
      ['1.2.* || 2.*', '2.1.3'],
      ['1.2.* || 2.*', '1.2.3'],
      ['1.2.* || 2.*', '1.2.3'],
      ['*', '1.2.3'],
      ['2', '2.1.2'],
      ['2.3', '2.3.1'],
      ['~2.4', '2.4.0'], # >=2.4.0 <2.5.0
      ['~2.4', '2.4.5'],
      ['~>3.2.1', '3.2.2'], # >=3.2.1 <3.3.0
      ['~1', '1.2.3'], # >=1.0.0 <2.0.0
      ['~>1', '1.2.3'],
      ['~> 1', '1.2.3'],
      ['~1.0', '1.0.2'], # >=1.0.0 <1.1.0
      ['~ 1.0', '1.0.2'],
      ['>=1', '1.0.0'],
      ['>= 1', '1.0.0'],
      ['<1.2', '1.1.1'],
      ['< 1.2', '1.1.1'],
      ['1', '1.0.0-beta'],
      ['~v0.5.4-pre', '0.5.5'],
      ['~v0.5.4-pre', '0.5.4'],
      ['=0.7.x', '0.7.2'],
      ['>=0.7.x', '0.7.2'],
      ['=0.7.x', '0.7.0-asdf'],
      ['>=0.7.x', '0.7.0-asdf'],
      ['<=0.7.x', '0.6.2'],
      ['>0.2.3 >0.2.4 <=0.2.5', '0.2.5'],
      ['>=0.2.3 <=0.2.4', '0.2.4'],
      ['1.0.0 - 2.0.0', '2.0.0'],
      ['^1', '0.0.0-0'],
      ['^3.0.0', '2.0.0'],
      ['^1.0.0 || ~2.0.1', '2.0.0'],
      ['^0.1.0 || ~3.0.1 || 5.0.0', '3.2.0'],
      ['^0.1.0 || ~3.0.1 || 5.0.0', '1.0.0-beta'],
      ['^0.1.0 || ~3.0.1 || 5.0.0', '5.0.0-0'],
      ['^0.1.0 || ~3.0.1 || >4 <=5.0.0', '3.5.0']
    ].each do |tuple|
      it "#{tuple[1]} should not be above range #{tuple[0]}(#{SemanticPuppet::VersionRange.parse(tuple[0]).inspect})" do
        expect(above(tuple[1], tuple[0])).to be_falsey
      end
    end

    [
      ['~1.2.2', '1.2.1'],
      ['~0.6.1-1', '0.6.1-0'],
      ['1.0.0 - 2.0.0', '0.0.1'],
      ['1.0.0-beta.2', '1.0.0-beta.1'],
      ['1.0.0', '0.0.0'],
      ['>=2.0.0', '1.1.1'],
      ['>=2.0.0', '1.2.9'],
      ['>2.0.0', '2.0.0'],
      ['0.1.20 || 1.2.4', '0.1.5'],
      ['2.x.x', '1.0.0'],
      ['1.2.x', '1.1.0'],
      ['1.2.x || 2.x', '1.0.0'],
      ['2.*.*', '1.0.1'],
      ['1.2.*', '1.1.3'],
      ['1.2.* || 2.*', '1.1.9999'],
      ['2', '1.0.0'],
      ['2.3', '2.2.2'],
      ['~2.4', '2.3.0'], # >=2.4.0 <2.5.0
      ['~2.4', '2.3.5'],
      ['~>3.2.1', '3.2.0'], # >=3.2.1 <3.3.0
      ['~1', '0.2.3'], # >=1.0.0 <2.0.0
      ['~>1', '0.2.4'],
      ['~> 1', '0.2.3'],
      ['~1.0', '0.1.2'], # >=1.0.0 <1.1.0
      ['~ 1.0', '0.1.0'],
      ['>1.2', '1.2.0'],
      ['> 1.2', '1.2.1'],
      ['1', '0.0.0-beta'],
      ['~v0.5.4-pre', '0.5.4-alpha'],
      ['~v0.5.4-pre', '0.5.4-alpha'],
      ['=0.7.x', '0.6.0'],
      ['=0.7.x', '0.6.0-asdf'],
      ['>=0.7.x', '0.6.0'],
      ['~1.2.2', '1.2.1'],
      ['1.0.0 - 2.0.0', '0.2.3'],
      ['1.0.0', '0.0.1'],
      ['>=2.0.0', '1.0.0'],
      ['>=2.0.0', '1.9999.9999'],
      ['>=2.0.0', '1.2.9'],
      ['>2.0.0', '2.0.0'],
      ['>2.0.0', '1.2.9'],
      ['2.x.x', '1.1.3'],
      ['1.2.x', '1.1.3'],
      ['1.2.x || 2.x', '1.1.3'],
      ['2.*.*', '1.1.3'],
      ['1.2.*', '1.1.3'],
      ['1.2.* || 2.*', '1.1.3'],
      ['2', '1.9999.9999'],
      ['2.3', '2.2.1'],
      ['~2.4', '2.3.0'], # >=2.4.0 <2.5.0
      ['~>3.2.1', '2.3.2'], # >=3.2.1 <3.3.0
      ['~1', '0.2.3'], # >=1.0.0 <2.0.0
      ['~>1', '0.2.3'],
      ['~1.0', '0.0.0'], # >=1.0.0 <1.1.0
      ['>1', '1.0.0'],
      ['2', '1.0.0-beta'],
      ['>1', '1.0.0-beta'],
      ['> 1', '1.0.0-beta'],
      ['=0.7.x', '0.6.2'],
      ['=0.7.x', '0.7.0-asdf'],
      ['^1', '1.0.0-0'],
      ['>=0.7.x', '0.7.0-asdf'],
      ['1', '1.0.0-beta'],
      ['>=0.7.x', '0.6.2']
    ].each do |tuple|
      it "#{tuple[1]} should be below range #{tuple[0]}" do
        expect(below(tuple[1], tuple[0])).to be_truthy
      end
    end

    [
      ['~ 1.0', '1.1.0'],
      ['~0.6.1-1', '0.6.1-1'],
      ['1.0.0 - 2.0.0', '1.2.3'],
      ['1.0.0 - 2.0.0', '2.9.9'],
      ['1.0.0', '1.0.0'],
      ['>=*', '0.2.4'],
      ['', '1.0.0'],
      ['*', '1.2.3'],
      ['>=1.0.0', '1.0.0'],
      ['>=1.0.0', '1.0.1'],
      ['>=1.0.0', '1.1.0'],
      ['>1.0.0', '1.0.1'],
      ['>1.0.0', '1.1.0'],
      ['<=2.0.0', '2.0.0'],
      ['<=2.0.0', '1.9999.9999'],
      ['<=2.0.0', '0.2.9'],
      ['<2.0.0', '1.9999.9999'],
      ['<2.0.0', '0.2.9'],
      ['>= 1.0.0', '1.0.0'],
      ['>=  1.0.0', '1.0.1'],
      ['>=   1.0.0', '1.1.0'],
      ['> 1.0.0', '1.0.1'],
      ['>  1.0.0', '1.1.0'],
      ['<=   2.0.0', '2.0.0'],
      ['<= 2.0.0', '1.9999.9999'],
      ['<=  2.0.0', '0.2.9'],
      ['<    2.0.0', '1.9999.9999'],
      ["<\t2.0.0", '0.2.9'],
      ['>=0.1.97', '0.1.97'],
      ['0.1.20 || 1.2.4', '1.2.4'],
      ['0.1.20 || >1.2.4', '1.2.4'],
      ['0.1.20 || 1.2.4', '1.2.3'],
      ['0.1.20 || 1.2.4', '0.1.20'],
      ['>=0.2.3 || <0.0.1', '0.0.0'],
      ['>=0.2.3 || <0.0.1', '0.2.3'],
      ['>=0.2.3 || <0.0.1', '0.2.4'],
      ['||', '1.3.4'],
      ['2.x.x', '2.1.3'],
      ['1.2.x', '1.2.3'],
      ['1.2.x || 2.x', '2.1.3'],
      ['1.2.x || 2.x', '1.2.3'],
      ['x', '1.2.3'],
      ['2.*.*', '2.1.3'],
      ['1.2.*', '1.2.3'],
      ['1.2.* || 2.*', '2.1.3'],
      ['1.2.* || 2.*', '1.2.3'],
      ['1.2.* || 2.*', '1.2.3'],
      ['*', '1.2.3'],
      ['2', '2.1.2'],
      ['2.3', '2.3.1'],
      ['~2.4', '2.4.0'], # >=2.4.0 <2.5.0
      ['~2.4', '2.4.5'],
      ['~>3.2.1', '3.2.2'], # >=3.2.1 <3.3.0
      ['~1', '1.2.3'], # >=1.0.0 <2.0.0
      ['~>1', '1.2.3'],
      ['~> 1', '1.2.3'],
      ['~1.0', '1.0.2'], # >=1.0.0 <1.1.0
      ['~ 1.0', '1.0.2'],
      ['>=1', '1.0.0'],
      ['>= 1', '1.0.0'],
      ['<1.2', '1.1.1'],
      ['< 1.2', '1.1.1'],
      ['~v0.5.4-pre', '0.5.5'],
      ['~v0.5.4-pre', '0.5.4'],
      ['=0.7.x', '0.7.2'],
      ['>=0.7.x', '0.7.2'],
      ['<=0.7.x', '0.6.2'],
      ['>0.2.3 >0.2.4 <=0.2.5', '0.2.5'],
      ['>=0.2.3 <=0.2.4', '0.2.4'],
      ['1.0.0 - 2.0.0', '2.0.0'],
      ['^3.0.0', '4.0.0'],
      ['^1.0.0 || ~2.0.1', '2.0.0'],
      ['^0.1.0 || ~3.0.1 || 5.0.0', '3.2.0'],
      ['^0.1.0 || ~3.0.1 || 5.0.0', '1.0.0-beta'],
      ['^0.1.0 || ~3.0.1 || 5.0.0', '5.0.0-0'],
      ['^0.1.0 || ~3.0.1 || >4 <=5.0.0', '3.5.0'],
      ['^1.0.0-alpha', '1.0.0-beta'],
      ['~1.0.0-alpha', '1.0.0-beta'],
      ['=0.1.0', '1.0.0']
    ].each do |tuple|
      it "#{tuple[1]} should not be below range #{tuple[0]}" do
        expect(below(tuple[1], tuple[0])).to be_falsey
      end
    end
  end
end
