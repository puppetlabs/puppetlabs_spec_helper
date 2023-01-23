require 'spec_helper'
require 'puppet/pops'

module Puppet::Pops
module Types
describe 'The type calculator' do
  let(:calculator) { TypeCalculator.new }

  def range_t(from, to)
   PIntegerType.new(from, to)
  end

  def pattern_t(*patterns)
    TypeFactory.pattern(*patterns)
  end

  def regexp_t(pattern)
    TypeFactory.regexp(pattern)
  end

  def string_t(string = nil)
    TypeFactory.string(string)
  end

  def constrained_string_t(size_type)
    TypeFactory.string(size_type)
  end

  def callable_t(*params)
    TypeFactory.callable(*params)
  end

  def all_callables_t
    TypeFactory.all_callables
  end

  def enum_t(*strings)
    TypeFactory.enum(*strings)
  end

  def variant_t(*types)
    TypeFactory.variant(*types)
  end

  def empty_variant_t()
    t = TypeFactory.variant()
    # assert this to ensure we did get an empty variant (or tests may pass when not being empty)
    raise 'typefactory did not return empty variant' unless t.types.empty?
    t
  end

  def type_alias_t(name, type_string)
    type_expr = Parser::EvaluatingParser.new.parse_string(type_string)
    TypeFactory.type_alias(name, type_expr)
  end

  def type_reference_t(type_string)
    TypeFactory.type_reference(type_string)
  end

  def integer_t
    TypeFactory.integer
  end

  def array_t(t, s = nil)
    TypeFactory.array_of(t, s)
  end

  def empty_array_t
    array_t(unit_t, range_t(0,0))
  end

  def hash_t(k,v,s = nil)
    TypeFactory.hash_of(v, k, s)
  end

  def data_t
    TypeFactory.data
  end

  def factory
    TypeFactory
  end

  def collection_t(size_type = nil)
    TypeFactory.collection(size_type)
  end

  def tuple_t(*types)
    TypeFactory.tuple(types)
  end

  def constrained_tuple_t(size_type, *types)
    TypeFactory.tuple(types, size_type)
  end

  def struct_t(type_hash)
    TypeFactory.struct(type_hash)
  end

  def any_t
    TypeFactory.any
  end

  def optional_t(t)
    TypeFactory.optional(t)
  end

  def type_t(t)
    TypeFactory.type_type(t)
  end

  def not_undef_t(t = nil)
    TypeFactory.not_undef(t)
  end

  def undef_t
    TypeFactory.undef
  end

  def unit_t
    # Cannot be created via factory, the type is private to the type system
    PUnitType::DEFAULT
  end

  def runtime_t(t, c)
    TypeFactory.runtime(t, c)
  end

  def object_t(hash)
    TypeFactory.object(hash)
  end

  def iterable_t(t = nil)
    TypeFactory.iterable(t)
  end

  def types
    Types
  end

  context 'when inferring ruby' do

    it 'integer translates to PIntegerType' do
      expect(calculator.infer(1).class).to eq(PIntegerType)
    end

    it 'large integer translates to PIntegerType' do
      expect(calculator.infer(2**33).class).to eq(PIntegerType)
    end

    it 'float translates to PFloatType' do
      expect(calculator.infer(1.3).class).to eq(PFloatType)
    end

    it 'string translates to PStringType' do
      expect(calculator.infer('foo').class).to eq(PStringType)
    end

    it 'inferred string type knows the string value' do
      t = calculator.infer('foo')
      expect(t.class).to eq(PStringType)
      expect(t.value).to eq('foo')
    end

    it 'boolean true translates to PBooleanType::TRUE' do
      expect(calculator.infer(true)).to eq(PBooleanType::TRUE)
    end

    it 'boolean false translates to PBooleanType::FALSE' do
      expect(calculator.infer(false)).to eq(PBooleanType::FALSE)
    end

    it 'regexp translates to PRegexpType' do
      expect(calculator.infer(/^a regular expression$/).class).to eq(PRegexpType)
    end

    it 'iterable translates to PIteratorType' do
      expect(calculator.infer(Iterable.on(1))).to be_a(PIteratorType)
    end

    it 'nil translates to PUndefType' do
      expect(calculator.infer(nil).class).to eq(PUndefType)
    end

    it ':undef translates to PUndefType' do
      expect(calculator.infer(:undef).class).to eq(PUndefType)
    end

    it 'an instance of class Foo translates to PRuntimeType[ruby, Foo]' do
      ::Foo = Class.new
      begin
        t = calculator.infer(::Foo.new)
        expect(t.class).to eq(PRuntimeType)
        expect(t.runtime).to eq(:ruby)
        expect(t.runtime_type_name).to eq('Foo')
      ensure
        Object.send(:remove_const, :Foo)
      end
    end

    it 'Class Foo translates to PTypeType[PRuntimeType[ruby, Foo]]' do
      ::Foo = Class.new
      begin
        t = calculator.infer(::Foo)
        expect(t.class).to eq(PTypeType)
        tt = t.type
        expect(tt.class).to eq(PRuntimeType)
        expect(tt.runtime).to eq(:ruby)
        expect(tt.runtime_type_name).to eq('Foo')
      ensure
        Object.send(:remove_const, :Foo)
      end
    end

    it 'Module FooModule translates to PTypeType[PRuntimeType[ruby, FooModule]]' do
      ::FooModule = Module.new
      begin
        t = calculator.infer(::FooModule)
        expect(t.class).to eq(PTypeType)
        tt = t.type
        expect(tt.class).to eq(PRuntimeType)
        expect(tt.runtime).to eq(:ruby)
        expect(tt.runtime_type_name).to eq('FooModule')
      ensure
        Object.send(:remove_const, :FooModule)
      end
    end

    context 'sensitive' do
      it 'translates to PSensitiveType' do
        expect(calculator.infer(PSensitiveType::Sensitive.new("hunter2")).class).to eq(PSensitiveType)
      end
    end

    context 'binary' do
      it 'translates to PBinaryType' do
        expect(calculator.infer(PBinaryType::Binary.from_binary_string("binary")).class).to eq(PBinaryType)
      end
    end

    context 'version' do
      it 'translates to PVersionType' do
        expect(calculator.infer(SemanticPuppet::Version.new(1,0,0)).class).to eq(PSemVerType)
      end

      it 'range translates to PVersionRangeType' do
        expect(calculator.infer(SemanticPuppet::VersionRange.parse('1.x')).class).to eq(PSemVerRangeType)
      end

      it 'translates to a limited PVersionType by infer_set' do
        v = SemanticPuppet::Version.new(1,0,0)
        t = calculator.infer_set(v)
        expect(t.class).to eq(PSemVerType)
        expect(t.ranges.size).to eq(1)
        expect(t.ranges[0].begin).to eq(v)
        expect(t.ranges[0].end).to eq(v)
      end
    end

    context 'timespan' do
      it 'translates to PTimespanType' do
        expect(calculator.infer(Time::Timespan.from_fields_hash('days' => 2))).to be_a(PTimespanType)
      end

      it 'translates to a limited PTimespanType by infer_set' do
        ts = Time::Timespan.from_fields_hash('days' => 2)
        t = calculator.infer_set(ts)
        expect(t.class).to eq(PTimespanType)
        expect(t.from).to be(ts)
        expect(t.to).to be(ts)
      end
    end

    context 'timestamp' do
      it 'translates to PTimespanType' do
        expect(calculator.infer(Time::Timestamp.now)).to be_a(PTimestampType)
      end

      it 'translates to a limited PTimespanType by infer_set' do
        ts = Time::Timestamp.now
        t = calculator.infer_set(ts)
        expect(t.class).to eq(PTimestampType)
        expect(t.from).to be(ts)
        expect(t.to).to be(ts)
      end
    end

    context 'array' do
      let(:derived) do
        Class.new(Array).new([1,2])
      end

      let(:derived_object) do
        Class.new(Array) do
          include PuppetObject

          def self._pcore_type
            @type ||= TypeFactory.object('name' => 'DerivedObjectArray')
          end
        end.new([1,2])
      end

      it 'translates to PArrayType' do
        expect(calculator.infer([1,2]).class).to eq(PArrayType)
      end

      it 'translates derived Array to PRuntimeType' do
        expect(calculator.infer(derived).class).to eq(PRuntimeType)
      end

      it 'translates derived Puppet Object Array to PObjectType' do
        expect(calculator.infer(derived_object).class).to eq(PObjectType)
      end

      it 'Instance of derived Array class is not instance of Array type' do
        expect(PArrayType::DEFAULT).not_to be_instance(derived)
      end

      it 'Instance of derived Array class is instance of Runtime type' do
        expect(runtime_t('ruby', nil)).to be_instance(derived)
      end

      it 'Instance of derived Puppet Object Array class is not instance of Array type' do
        expect(PArrayType::DEFAULT).not_to be_instance(derived_object)
      end

      it 'Instance of derived Puppet Object Array class is instance of Object type' do
        expect(object_t('name' => 'DerivedObjectArray')).to be_instance(derived_object)
      end

      it 'with integer values translates to PArrayType[PIntegerType]' do
        expect(calculator.infer([1,2]).element_type.class).to eq(PIntegerType)
      end

      it 'with 32 and 64 bit integer values translates to PArrayType[PIntegerType]' do
        expect(calculator.infer([1,2**33]).element_type.class).to eq(PIntegerType)
      end

      it 'Range of integer values are computed' do
        t = calculator.infer([-3,0,42]).element_type
        expect(t.class).to eq(PIntegerType)
        expect(t.from).to eq(-3)
        expect(t.to).to eq(42)
      end

      it 'Compound string values are converted to enums' do
        t = calculator.infer(['a','b', 'c']).element_type
        expect(t.class).to eq(PEnumType)
        expect(t.values).to eq(['a', 'b', 'c'])
      end

      it 'with integer and float values translates to PArrayType[PNumericType]' do
        expect(calculator.infer([1,2.0]).element_type.class).to eq(PNumericType)
      end

      it 'with integer and string values translates to PArrayType[PScalarDataType]' do
        expect(calculator.infer([1,'two']).element_type.class).to eq(PScalarDataType)
      end

      it 'with float and string values translates to PArrayType[PScalarDataType]' do
        expect(calculator.infer([1.0,'two']).element_type.class).to eq(PScalarDataType)
      end

      it 'with integer, float, and string values translates to PArrayType[PScalarDataType]' do
        expect(calculator.infer([1, 2.0,'two']).element_type.class).to eq(PScalarDataType)
      end

      it 'with integer and regexp values translates to PArrayType[PScalarType]' do
        expect(calculator.infer([1, /two/]).element_type.class).to eq(PScalarType)
      end

      it 'with string and regexp values translates to PArrayType[PScalarType]' do
        expect(calculator.infer(['one', /two/]).element_type.class).to eq(PScalarType)
      end

      it 'with string and symbol values translates to PArrayType[PAnyType]' do
        expect(calculator.infer(['one', :two]).element_type.class).to eq(PAnyType)
      end

      it 'with integer and nil values translates to PArrayType[PIntegerType]' do
        expect(calculator.infer([1, nil]).element_type.class).to eq(PIntegerType)
      end

      it 'with integer value, and array of string values, translates to Array[Data]' do
        expect(calculator.infer([1, ['two']]).element_type.name).to eq('Data')
      end

      it 'with integer value, and hash of string => string values, translates to Array[Data]' do
        expect(calculator.infer([1, {'two' => 'three'} ]).element_type.name).to eq('Data')
      end

      it 'with integer value, and hash of integer => string values, translates to Array[RichData]' do
        expect(calculator.infer([1, {2 => 'three'} ]).element_type.name).to eq('RichData')
      end

      it 'with integer, regexp, and binary values translates to Array[RichData]' do
        expect(calculator.infer([1, /two/, PBinaryType::Binary.from_string('three')]).element_type.name).to eq('RichData')
      end

      it 'with arrays of string values translates to PArrayType[PArrayType[PStringType]]' do
        et = calculator.infer([['first', 'array'], ['second','array']])
        expect(et.class).to eq(PArrayType)
        et = et.element_type
        expect(et.class).to eq(PArrayType)
        et = et.element_type
        expect(et.class).to eq(PEnumType)
      end

      it 'with array of string values and array of integers translates to PArrayType[PArrayType[PScalarDataType]]' do
        et = calculator.infer([['first', 'array'], [1,2]])
        expect(et.class).to eq(PArrayType)
        et = et.element_type
        expect(et.class).to eq(PArrayType)
        et = et.element_type
        expect(et.class).to eq(PScalarDataType)
      end

      it 'with hashes of string values translates to PArrayType[PHashType[PEnumType]]' do
        et = calculator.infer([{:first => 'first', :second => 'second' }, {:first => 'first', :second => 'second' }])
        expect(et.class).to eq(PArrayType)
        et = et.element_type
        expect(et.class).to eq(PHashType)
        et = et.value_type
        expect(et.class).to eq(PEnumType)
      end

      it 'with hash of string values and hash of integers translates to PArrayType[PHashType[PScalarDataType]]' do
        et = calculator.infer([{:first => 'first', :second => 'second' }, {:first => 1, :second => 2 }])
        expect(et.class).to eq(PArrayType)
        et = et.element_type
        expect(et.class).to eq(PHashType)
        et = et.value_type
        expect(et.class).to eq(PScalarDataType)
      end
    end

    context 'hash' do
      let(:derived) do
        Class.new(Hash)[:first => 1, :second => 2]
      end

      let(:derived_object) do
        Class.new(Hash) do
          include PuppetObject

          def self._pcore_type
            @type ||= TypeFactory.object('name' => 'DerivedObjectHash')
          end
        end[:first => 1, :second => 2]
      end

      it 'translates to PHashType' do
        expect(calculator.infer({:first => 1, :second => 2}).class).to eq(PHashType)
      end

      it 'translates derived Hash to PRuntimeType' do
        expect(calculator.infer(derived).class).to eq(PRuntimeType)
      end

      it 'translates derived Puppet Object Hash to PObjectType' do
        expect(calculator.infer(derived_object).class).to eq(PObjectType)
      end

      it 'Instance of derived Hash class is not instance of Hash type' do
        expect(PHashType::DEFAULT).not_to be_instance(derived)
      end

      it 'Instance of derived Hash class is instance of Runtime type' do
        expect(runtime_t('ruby', nil)).to be_instance(derived)
      end

      it 'Instance of derived Puppet Object Hash class is not instance of Hash type' do
        expect(PHashType::DEFAULT).not_to be_instance(derived_object)
      end

      it 'Instance of derived Puppet Object Hash class is instance of Object type' do
        expect(object_t('name' => 'DerivedObjectHash')).to be_instance(derived_object)
      end

      it 'with symbolic keys translates to PHashType[PRuntimeType[ruby, Symbol], value]' do
        k = calculator.infer({:first => 1, :second => 2}).key_type
        expect(k.class).to eq(PRuntimeType)
        expect(k.runtime).to eq(:ruby)
        expect(k.runtime_type_name).to eq('Symbol')
      end

      it 'with string keys translates to PHashType[PEnumType, value]' do
        expect(calculator.infer({'first' => 1, 'second' => 2}).key_type.class).to eq(PEnumType)
      end

      it 'with integer values translates to PHashType[key, PIntegerType]' do
        expect(calculator.infer({:first => 1, :second => 2}).value_type.class).to eq(PIntegerType)
      end

      it 'when empty infers a type that answers true to is_the_empty_hash?' do
        expect(calculator.infer({}).is_the_empty_hash?).to eq(true)
        expect(calculator.infer_set({}).is_the_empty_hash?).to eq(true)
      end

      it 'when empty is assignable to any PHashType' do
        expect(calculator.assignable?(hash_t(string_t, string_t), calculator.infer({}))).to eq(true)
      end

      it 'when empty is not assignable to a PHashType with from size > 0' do
        expect(calculator.assignable?(hash_t(string_t,string_t,range_t(1, 1)), calculator.infer({}))).to eq(false)
      end

      context 'using infer_set' do
        it "with 'first' and 'second' keys translates to PStructType[{first=>value,second=>value}]" do
          t = calculator.infer_set({'first' => 1, 'second' => 2})
          expect(t.class).to eq(PStructType)
          expect(t.elements.size).to eq(2)
          expect(t.elements.map { |e| e.name }.sort).to eq(['first', 'second'])
        end

        it 'with string keys and string and array values translates to PStructType[{key1=>PStringType,key2=>PTupleType}]' do
          t = calculator.infer_set({ 'mode' => 'read', 'path' => ['foo', 'fee' ] })
          expect(t.class).to eq(PStructType)
          expect(t.elements.size).to eq(2)
          els = t.elements.map { |e| e.value_type }.sort {|a,b| a.to_s <=> b.to_s }
          expect(els[0].class).to eq(PStringType)
          expect(els[1].class).to eq(PTupleType)
        end

        it 'with mixed string and non-string keys translates to PHashType' do
          t = calculator.infer_set({ 1 => 'first', 'second' => 'second' })
          expect(t.class).to eq(PHashType)
        end

        it 'with empty string keys translates to PHashType' do
          t = calculator.infer_set({ '' => 'first', 'second' => 'second' })
          expect(t.class).to eq(PHashType)
        end
      end
    end

    it 'infers an instance of an anonymous class to Runtime[ruby]' do
      cls = Class.new do
        attr_reader :name
        def initialize(name)
          @name = name
        end
      end
      t = calculator.infer(cls.new('test'))
      expect(t.class).to eql(PRuntimeType)
      expect(t.runtime).to eql(:ruby)
      expect(t.name_or_pattern).to eql(nil)
    end
  end

  context 'patterns' do
    it 'constructs a PPatternType' do
      t = pattern_t('a(b)c')
      expect(t.class).to eq(PPatternType)
      expect(t.patterns.size).to eq(1)
      expect(t.patterns[0].class).to eq(PRegexpType)
      expect(t.patterns[0].pattern).to eq('a(b)c')
      expect(t.patterns[0].regexp.match('abc')[1]).to eq('b')
    end

    it 'constructs a PEnumType with multiple strings' do
      t = enum_t('a', 'b', 'c', 'abc')
      expect(t.values).to eq(['a', 'b', 'c', 'abc'].sort)
    end
  end

  # Deal with cases not covered by computing common type
  context 'when computing common type' do
    it 'computes given resource type commonality' do
      r1 = PResourceType.new('File', nil)
      r2 = PResourceType.new('File', nil)
      expect(calculator.common_type(r1, r2).to_s).to eq('File')


      r2 = PResourceType.new('File', '/tmp/foo')
      expect(calculator.common_type(r1, r2).to_s).to eq('File')

      r1 = PResourceType.new('File', '/tmp/foo')
      expect(calculator.common_type(r1, r2).to_s).to eq("File['/tmp/foo']")

      r1 = PResourceType.new('File', '/tmp/bar')
      expect(calculator.common_type(r1, r2).to_s).to eq('File')

      r2 = PResourceType.new('Package', 'apache')
      expect(calculator.common_type(r1, r2).to_s).to eq('Resource')
    end

    it 'computes given hostclass type commonality' do
      r1 = PClassType.new('foo')
      r2 = PClassType.new('foo')
      expect(calculator.common_type(r1, r2).to_s).to eq('Class[foo]')

      r2 = PClassType.new('bar')
      expect(calculator.common_type(r1, r2).to_s).to eq('Class')

      r2 = PClassType.new(nil)
      expect(calculator.common_type(r1, r2).to_s).to eq('Class')

      r1 = PClassType.new(nil)
      expect(calculator.common_type(r1, r2).to_s).to eq('Class')
    end

    context 'of strings' do
      it 'computes commonality' do
        t1 = string_t('abc')
        t2 = string_t('xyz')
        common_t = calculator.common_type(t1,t2)
        expect(common_t.class).to eq(PEnumType)
        expect(common_t.values).to eq(['abc', 'xyz'])
      end

      it 'computes common size_type' do
        t1 = constrained_string_t(range_t(3,6))
        t2 = constrained_string_t(range_t(2,4))
        common_t = calculator.common_type(t1,t2)
        expect(common_t.class).to eq(PStringType)
        expect(common_t.size_type).to eq(range_t(2,6))
      end

      it 'computes common size_type to be undef when one of the types has no size_type' do
        t1 = string_t
        t2 = constrained_string_t(range_t(2,4))
        common_t = calculator.common_type(t1,t2)
        expect(common_t.class).to eq(PStringType)
        expect(common_t.size_type).to be_nil
      end

      it 'computes values to be empty if the one has empty values' do
        t1 = string_t('apa')
        t2 = constrained_string_t(range_t(2,4))
        common_t = calculator.common_type(t1,t2)
        expect(common_t.class).to eq(PStringType)
        expect(common_t.value).to be_nil
      end
    end

    it 'computes pattern commonality' do
      t1 = pattern_t('abc')
      t2 = pattern_t('xyz')
      common_t = calculator.common_type(t1,t2)
      expect(common_t.class).to eq(PPatternType)
      expect(common_t.patterns.map { |pr| pr.pattern }).to eq(['abc', 'xyz'])
      expect(common_t.to_s).to eq('Pattern[/abc/, /xyz/]')
    end

    it 'computes enum commonality to value set sum' do
      t1 = enum_t('a', 'b', 'c')
      t2 = enum_t('x', 'y', 'z')
      common_t = calculator.common_type(t1, t2)
      expect(common_t).to eq(enum_t('a', 'b', 'c', 'x', 'y', 'z'))
    end

    it 'computed variant commonality to type union where added types are not sub-types' do
      a_t1 = integer_t
      a_t2 = enum_t('b')
      v_a = variant_t(a_t1, a_t2)
      b_t1 = integer_t
      b_t2 = enum_t('a')
      v_b = variant_t(b_t1, b_t2)
      common_t = calculator.common_type(v_a, v_b)
      expect(common_t.class).to eq(PVariantType)
      expect(Set.new(common_t.types)).to  eq(Set.new([a_t1, a_t2, b_t1, b_t2]))
    end

    it 'computed variant commonality to type union where added types are sub-types' do
      a_t1 = integer_t
      a_t2 = string_t
      v_a = variant_t(a_t1, a_t2)
      b_t1 = integer_t
      b_t2 = enum_t('a')
      v_b = variant_t(b_t1, b_t2)
      common_t = calculator.common_type(v_a, v_b)
      expect(common_t.class).to eq(PVariantType)
      expect(Set.new(common_t.types)).to  eq(Set.new([a_t1, a_t2]))
    end

    context 'commonality of scalar data types' do
      it 'Numeric and String == ScalarData' do
        expect(calculator.common_type(PNumericType::DEFAULT, PStringType::DEFAULT).class).to eq(PScalarDataType)
      end

      it 'Numeric and Boolean == ScalarData' do
        expect(calculator.common_type(PNumericType::DEFAULT, PBooleanType::DEFAULT).class).to eq(PScalarDataType)
      end

      it 'String and Boolean == ScalarData' do
        expect(calculator.common_type(PStringType::DEFAULT, PBooleanType::DEFAULT).class).to eq(PScalarDataType)
      end
    end

    context 'commonality of scalar types' do
      it 'Regexp and Integer == Scalar' do
        expect(calculator.common_type(PRegexpType::DEFAULT, PScalarDataType::DEFAULT).class).to eq(PScalarType)
      end

      it 'Regexp and SemVer == ScalarData' do
        expect(calculator.common_type(PRegexpType::DEFAULT, PSemVerType::DEFAULT).class).to eq(PScalarType)
      end

      it 'Timestamp and Timespan == ScalarData' do
        expect(calculator.common_type(PTimestampType::DEFAULT, PTimespanType::DEFAULT).class).to eq(PScalarType)
      end

      it 'Timestamp and Boolean == ScalarData' do
        expect(calculator.common_type(PTimestampType::DEFAULT, PBooleanType::DEFAULT).class).to eq(PScalarType)
      end
    end

    context 'of callables' do
      it 'incompatible instances => generic callable' do
        t1 = callable_t(String)
        t2 = callable_t(Integer)
        common_t = calculator.common_type(t1, t2)
        expect(common_t.class).to be(PCallableType)
        expect(common_t.param_types).to be_nil
        expect(common_t.block_type).to be_nil
      end

      it 'compatible instances => the most specific' do
        t1 = callable_t(String)
        scalar_t = PScalarType.new
        t2 = callable_t(scalar_t)
        common_t = calculator.common_type(t1, t2)
        expect(common_t.class).to be(PCallableType)
        expect(common_t.param_types.class).to be(PTupleType)
        expect(common_t.param_types.types).to eql([string_t])
        expect(common_t.block_type).to be_nil
      end

      it 'block_type is included in the check (incompatible block)' do
        b1 = callable_t(String)
        b2 = callable_t(Integer)
        t1 = callable_t(String, b1)
        t2 = callable_t(String, b2)
        common_t = calculator.common_type(t1, t2)
        expect(common_t.class).to be(PCallableType)
        expect(common_t.param_types).to be_nil
        expect(common_t.block_type).to be_nil
      end

      it 'block_type is included in the check (compatible block)' do
        b1 = callable_t(String)
        t1 = callable_t(String, b1)
        scalar_t = PScalarType::DEFAULT
        b2 = callable_t(scalar_t)
        t2 = callable_t(String, b2)
        common_t = calculator.common_type(t1, t2)
        expect(common_t.param_types.class).to be(PTupleType)
        expect(common_t.block_type).to eql(callable_t(scalar_t))
      end

      it 'return_type is included in the check (incompatible return_type)' do
        t1 = callable_t([String], String)
        t2 = callable_t([String], Integer)
        common_t = calculator.common_type(t1, t2)
        expect(common_t.class).to be(PCallableType)
        expect(common_t.param_types).to be_nil
        expect(common_t.return_type).to be_nil
      end

      it 'return_type is included in the check (compatible return_type)' do
        t1 = callable_t([String], Numeric)
        t2 = callable_t([String], Integer)
        common_t = calculator.common_type(t1, t2)
        expect(common_t.class).to be(PCallableType)
        expect(common_t.param_types).to be_a(PTupleType)
        expect(common_t.return_type).to eql(PNumericType::DEFAULT)
      end
    end
  end

  context 'computes assignability' do
    include_context 'types_setup'

    it 'such that all types are assignable to themselves' do
      all_types.each do |tc|
        t = tc::DEFAULT
        expect(t).to be_assignable_to(t)
      end
    end

    context 'for Unit, such that' do
      it 'all types are assignable to Unit' do
        t = PUnitType::DEFAULT
        all_types.each { |t2| expect(t2::DEFAULT).to be_assignable_to(t) }
      end

      it 'Unit is assignable to all other types' do
        t = PUnitType::DEFAULT
        all_types.each { |t2| expect(t).to be_assignable_to(t2::DEFAULT) }
      end

      it 'Unit is assignable to Unit' do
        t = PUnitType::DEFAULT
        t2 = PUnitType::DEFAULT
        expect(t).to be_assignable_to(t2)
      end
    end

    context 'for Any, such that' do
      it 'all types are assignable to Any' do
        t = PAnyType::DEFAULT
        all_types.each { |t2| expect(t2::DEFAULT).to be_assignable_to(t) }
      end

      it 'Any is not assignable to anything but Any and Optional (implied Optional[Any])' do
        tested_types = all_types() - [PAnyType, POptionalType]
        t = PAnyType::DEFAULT
        tested_types.each { |t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end
    end

    context "for NotUndef, such that" do
      it 'all types except types assignable from Undef are assignable to NotUndef' do
        t = not_undef_t
        tc = TypeCalculator.singleton
        undef_t = PUndefType::DEFAULT
        all_types.each do |c|
          t2 = c::DEFAULT
          if tc.assignable?(t2, undef_t)
            expect(t2).not_to be_assignable_to(t)
          else
            expect(t2).to be_assignable_to(t)
          end
        end
      end

      it 'type NotUndef[T] is assignable from T unless T is assignable from Undef ' do
        tc = TypeCalculator.singleton
        undef_t = PUndefType::DEFAULT
        all_types().select do |c|
          t2 = c::DEFAULT
          not_undef_t = not_undef_t(t2)
          if tc.assignable?(t2, undef_t)
            expect(t2).not_to be_assignable_to(not_undef_t)
          else
            expect(t2).to be_assignable_to(not_undef_t)
          end
        end
      end

      it 'type T is assignable from NotUndef[T] unless T is assignable from Undef' do
        tc = TypeCalculator.singleton
        undef_t = PUndefType::DEFAULT
        all_types().select do |c|
          t2 = c::DEFAULT
          not_undef_t = not_undef_t(t2)
          unless tc.assignable?(t2, undef_t)
            expect(not_undef_t).to be_assignable_to(t2)
          end
        end
      end
    end

    context "for TypeReference, such that" do
      it 'no other type is assignable' do
        t = PTypeReferenceType::DEFAULT
        all_instances = (all_types - [
          PTypeReferenceType, # Avoid comparison with t
          PTypeAliasType      # DEFAULT resolves to PTypeReferenceType::DEFAULT, i.e. t
        ]).map {|c| c::DEFAULT }

        # Add a non-empty variant
        all_instances << variant_t(PAnyType::DEFAULT, PUnitType::DEFAULT)
        # Add a type alias that doesn't resolve to 't'
        all_instances << type_alias_t('MyInt', 'Integer').resolve(nil)

        all_instances.each { |i| expect(i).not_to be_assignable_to(t) }
      end

      it 'a TypeReference to the exact same type is assignable' do
        expect(type_reference_t('Integer[0,10]')).to be_assignable_to(type_reference_t('Integer[0,10]'))
      end

      it 'a TypeReference to the different type is not assignable' do
        expect(type_reference_t('String')).not_to be_assignable_to(type_reference_t('Integer'))
      end

      it 'a TypeReference to the different type is not assignable even if the referenced type is' do
        expect(type_reference_t('Integer[1,2]')).not_to be_assignable_to(type_reference_t('Integer[0,3]'))
      end
    end

    context 'for Data, such that' do
      let(:data) { TypeFactory.data }
      data_compatible_types.map { |t2| type_from_class(t2) }.each do |tc|
        it "it is assignable from #{tc.name}" do
          expect(tc).to be_assignable_to(data)
        end
      end

      data_compatible_types.map { |t2| type_from_class(t2) }.each do |tc|
        it "it is assignable from Optional[#{tc.name}]" do
          expect(optional_t(tc)).to be_assignable_to(data)
        end
      end

      it 'it is not assignable to any of its subtypes' do
        types_to_test = data_compatible_types
        types_to_test.each {|t2| expect(data).not_to be_assignable_to(type_from_class(t2)) }
      end

      it 'it is not assignable to any disjunct type' do
        tested_types = all_types - [PAnyType, POptionalType, PInitType] - scalar_data_types
        tested_types.each {|t2| expect(data).not_to be_assignable_to(t2::DEFAULT) }
      end
    end

    context 'for Rich Data, such that' do
      let(:rich_data) { TypeFactory.rich_data }
      rich_data_compatible_types.map { |t2| type_from_class(t2) }.each do |tc|
        it "it is assignable from #{tc.name}" do
          expect(tc).to be_assignable_to(rich_data)
        end
      end

      rich_data_compatible_types.map { |t2| type_from_class(t2) }.each do |tc|
        it "it is assignable from Optional[#{tc.name}]" do
          expect(optional_t(tc)).to be_assignable_to(rich_data)
        end
      end

      it 'it is not assignable to any of its subtypes' do
        types_to_test = rich_data_compatible_types
        types_to_test.each {|t2| expect(rich_data).not_to be_assignable_to(type_from_class(t2)) }
      end

      it 'it is not assignable to any disjunct type' do
        tested_types = all_types - [PAnyType, POptionalType, PInitType] - scalar_types
        tested_types.each {|t2| expect(rich_data).not_to be_assignable_to(t2::DEFAULT) }
      end
    end

    context 'for Variant, such that' do
      it 'it is assignable to a type if all contained types are assignable to that type' do
        v = variant_t(range_t(10, 12),range_t(14, 20))
        expect(v).to be_assignable_to(integer_t)
        expect(v).to be_assignable_to(range_t(10, 20))

        # test that both types are assignable to one of the variants OK
        expect(v).to be_assignable_to(variant_t(range_t(10, 20), range_t(30, 40)))

        # test where each type is assignable to different types in a variant is OK
        expect(v).to be_assignable_to(variant_t(range_t(10, 13), range_t(14, 40)))

        # not acceptable
        expect(v).not_to be_assignable_to(range_t(0, 4))
        expect(v).not_to be_assignable_to(string_t)
      end

      it 'an empty Variant is assignable to another empty Variant' do
        expect(empty_variant_t).to be_assignable_to(empty_variant_t)
      end

      it 'an empty Variant is assignable to Any' do
        expect(empty_variant_t).to be_assignable_to(PAnyType::DEFAULT)
      end

      it 'an empty Variant is assignable to Unit' do
        expect(empty_variant_t).to be_assignable_to(PUnitType::DEFAULT)
      end

      it 'an empty Variant is not assignable to any type except empty Variant, Any, NotUndef, and Unit' do
        assignables = [PUnitType, PAnyType, PNotUndefType]
        unassignables = all_types - assignables
        unassignables.each {|t2| expect(empty_variant_t).not_to be_assignable_to(t2::DEFAULT) }
        assignables.each   {|t2| expect(empty_variant_t).to be_assignable_to(t2::DEFAULT) }
      end

      it 'an empty Variant is not assignable to Optional[Any] since it is not assignable to Undef' do
        opt_any = optional_t(any_t)
        expect(empty_variant_t).not_to be_assignable_to(opt_any)
      end

      it 'an Optional[Any] is not assignable to empty Variant' do
        opt_any = optional_t(any_t)
        expect(opt_any).not_to be_assignable_to(empty_variant_t)
      end

      it 'an empty Variant is assignable to NotUndef[Variant] since Variant is not Undef' do
        not_undef_variant = not_undef_t(empty_variant_t)
        expect(empty_variant_t).to be_assignable_to(not_undef_variant)
      end

      it 'a NotUndef[Variant] is assignable to empty Variant' do
        not_undef_variant = not_undef_t(empty_variant_t)
        expect(not_undef_variant).to be_assignable_to(empty_variant_t)
      end
    end

    context 'for Scalar, such that' do
      it 'all scalars are assignable to Scalar' do
        t = PScalarType::DEFAULT
        scalar_types.each {|t2| expect(t2::DEFAULT).to be_assignable_to(t) }
      end

      it 'Scalar is not assignable to any of its subtypes' do
        t = PScalarType::DEFAULT
        types_to_test = scalar_types - [PScalarType]
        types_to_test.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end

      it 'Scalar is not assignable to any disjunct type' do
        tested_types = all_types - [PAnyType, POptionalType, PInitType, PNotUndefType] - scalar_types
        t = PScalarType::DEFAULT
        tested_types.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end
    end

    context 'for Numeric, such that' do
      it 'all numerics are assignable to Numeric' do
        t = PNumericType::DEFAULT
        numeric_types.each {|t2| expect(t2::DEFAULT).to be_assignable_to(t) }
      end

      it 'Numeric is not assignable to any of its subtypes' do
        t = PNumericType::DEFAULT
        types_to_test = numeric_types - [PNumericType]
        types_to_test.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end

      it 'Numeric does not consider ruby Rational to be an instance' do
        t = PNumericType::DEFAULT
        expect(t).not_to be_instance(Rational(2,3))
      end

      it 'Numeric is not assignable to any disjunct type' do
        tested_types = all_types - [
          PAnyType,
          POptionalType,
          PInitType,
          PNotUndefType,
          PScalarType,
          PScalarDataType,
          ] - numeric_types
        t = PNumericType::DEFAULT
        tested_types.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end
    end

    context 'for Collection, such that' do
      it 'all collections are assignable to Collection' do
        t = PCollectionType::DEFAULT
        collection_types.each {|t2| expect(t2::DEFAULT).to be_assignable_to(t) }
      end

      it 'Collection is not assignable to any of its subtypes' do
        t = PCollectionType::DEFAULT
        types_to_test = collection_types - [PCollectionType]
        types_to_test.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end

      it 'Collection is not assignable to any disjunct type' do
        tested_types = all_types - [
          PAnyType,
          POptionalType,
          PNotUndefType,
          PIterableType] - collection_types
        t = PCollectionType::DEFAULT
        tested_types.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end
    end

    context 'for Array, such that' do
      it 'Array is not assignable to non Array based Collection type' do
        t = PArrayType::DEFAULT
        tested_types = collection_types - [
          PCollectionType,
          PNotUndefType,
          PArrayType,
          PTupleType]
        tested_types.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end

      it 'Array is not assignable to any disjunct type' do
        tested_types = all_types - [
          PAnyType,
          POptionalType,
          PNotUndefType,
          PIterableType] - collection_types
        t = PArrayType::DEFAULT
        tested_types.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end

      it 'Empty Array is assignable to an array that accepts 0 entries' do
        expect(empty_array_t).to be_assignable_to(array_t(string_t))
        expect(empty_array_t).to be_assignable_to(array_t(integer_t))
      end

      it 'A Tuple is assignable to an array' do
        expect(tuple_t(String)).to be_assignable_to(array_t(String))
      end

      it 'A Tuple with <n> elements is assignable to an array with min size <n>' do
        expect(tuple_t(String,String)).to be_assignable_to(array_t(String, range_t(2, :default)))
      end

      it 'A Tuple with <n> elements where the last 2 are optional is assignable to an array with size <n> - 2' do
        expect(constrained_tuple_t(range_t(2, :default), String,String,String,String)).to be_assignable_to(array_t(String, range_t(2, :default)))
      end
    end

    context 'for Enum, such that' do
      it 'Enum is assignable to an Enum with all contained options' do
        expect(enum_t('a', 'b')).to be_assignable_to(enum_t('a', 'b', 'c'))
      end

      it 'Enum is not assignable to an Enum with fewer contained options' do
        expect(enum_t('a', 'b')).not_to be_assignable_to(enum_t('a'))
      end

      it 'case insensitive Enum is not assignable to case sensitive Enum' do
        expect(enum_t('a', 'b', true)).not_to be_assignable_to(enum_t('a', 'b'))
      end

      it 'case sensitive Enum is assignable to case insensitive Enum' do
        expect(enum_t('a', 'b')).to be_assignable_to(enum_t('a', 'b', true))
      end

      it 'case sensitive Enum is not assignable to case sensitive Enum using different case' do
        expect(enum_t('a', 'b')).not_to be_assignable_to(enum_t('A', 'B'))
      end

      it 'case sensitive Enum is assignable to case insensitive Enum using different case' do
        expect(enum_t('a', 'b')).to be_assignable_to(enum_t('A', 'B', true))
      end
    end

    context 'for Hash, such that' do
      it 'Hash is not assignable to any other Collection type' do
        t = PHashType::DEFAULT
        tested_types = collection_types - [
          PCollectionType,
          PStructType,
          PHashType]
        tested_types.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end

      it 'Hash is not assignable to any disjunct type' do
        tested_types = all_types - [
          PAnyType,
          POptionalType,
          PNotUndefType,
          PIterableType] - collection_types
        t = PHashType::DEFAULT
        tested_types.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end

      it 'Struct is assignable to Hash with Pattern that matches all keys' do
        expect(struct_t({'x' => integer_t, 'y' => integer_t})).to be_assignable_to(hash_t(pattern_t(/^\w+$/), factory.any))
      end

      it 'Struct is assignable to Hash with Enum that matches all keys' do
        expect(struct_t({'x' => integer_t, 'y' => integer_t})).to be_assignable_to(hash_t(enum_t('x', 'y', 'z'), factory.any))
      end

      it 'Struct is not assignable to Hash with Pattern unless all keys match' do
        expect(struct_t({'a' => integer_t, 'A' => integer_t})).not_to be_assignable_to(hash_t(pattern_t(/^[A-Z]+$/), factory.any))
      end

      it 'Struct is not assignable to Hash with Enum unless all keys match' do
        expect(struct_t({'a' => integer_t, 'y' => integer_t})).not_to be_assignable_to(hash_t(enum_t('x', 'y', 'z'), factory.any))
      end
    end

    context 'for Timespan such that' do
      it 'Timespan is assignable to less constrained Timespan' do
        t1 = PTimespanType.new('00:00:10', '00:00:20')
        t2 = PTimespanType.new('00:00:11', '00:00:19')
        expect(t2).to be_assignable_to(t1)
      end

      it 'Timespan is not assignable to more constrained Timespan' do
        t1 = PTimespanType.new('00:00:10', '00:00:20')
        t2 = PTimespanType.new('00:00:11', '00:00:19')
        expect(t1).not_to be_assignable_to(t2)
      end
    end

    context 'for Timestamp such that' do
      it 'Timestamp is assignable to less constrained Timestamp' do
        t1 = PTimestampType.new('2016-01-01', '2016-12-31')
        t2 = PTimestampType.new('2016-02-01', '2016-11-30')
        expect(t2).to be_assignable_to(t1)
      end

      it 'Timestamp is not assignable to more constrained Timestamp' do
        t1 = PTimestampType.new('2016-01-01', '2016-12-31')
        t2 = PTimestampType.new('2016-02-01', '2016-11-30')
        expect(t1).not_to be_assignable_to(t2)
      end
    end

    context 'for Tuple, such that' do
      it 'Tuple is not assignable to any other non Array based Collection type' do
        t = PTupleType::DEFAULT
        tested_types = collection_types - [
          PCollectionType,
          PTupleType,
          PArrayType]
        tested_types.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end

      it 'A tuple with parameters is assignable to the default Tuple' do
        t = PTupleType::DEFAULT
        t2 = PTupleType.new([PStringType::DEFAULT])
        expect(t2).to be_assignable_to(t)
      end

      it 'Tuple is not assignable to any disjunct type' do
        tested_types = all_types - [
          PAnyType,
          POptionalType,
          PInitType,
          PNotUndefType,
          PIterableType] - collection_types
        t = PTupleType::DEFAULT
        tested_types.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end
    end

    context 'for Struct, such that' do
      it 'Struct is not assignable to any other non Hashed based Collection type' do
        t = PStructType::DEFAULT
        tested_types = collection_types - [
          PCollectionType,
          PStructType,
          PHashType,
          PInitType]
        tested_types.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end

      it 'Struct is not assignable to any disjunct type' do
        tested_types = all_types - [
          PAnyType,
          POptionalType,
          PNotUndefType,
          PIterableType,
          PInitType] - collection_types
        t = PStructType::DEFAULT
        tested_types.each {|t2| expect(t).not_to be_assignable_to(t2::DEFAULT) }
      end

      it 'Default key optionality is controlled by value assignability to undef' do
        t1 = struct_t({'member' => string_t})
        expect(t1.elements[0].key_type).to eq(string_t('member'))
        t1 = struct_t({'member' => any_t})
        expect(t1.elements[0].key_type).to eq(optional_t(string_t('member')))
      end

      it "NotUndef['key'] becomes String['key'] (since its implied that String is required)" do
        t1 = struct_t({not_undef_t('member') => string_t})
        expect(t1.elements[0].key_type).to eq(string_t('member'))
      end

      it "Optional['key'] becomes Optional[String['key']]" do
        t1 = struct_t({optional_t('member') => string_t})
        expect(t1.elements[0].key_type).to eq(optional_t(string_t('member')))
      end

      it 'Optional members are not required' do
        t1 = struct_t({optional_t('optional_member') => string_t, not_undef_t('other_member') => string_t})
        t2 = struct_t({not_undef_t('other_member') => string_t})
        expect(t2).to be_assignable_to(t1)
      end

      it 'Required members not optional even when value is' do
        t1 = struct_t({not_undef_t('required_member') => any_t, not_undef_t('other_member') => string_t})
        t2 = struct_t({not_undef_t('other_member') => string_t})
        expect(t2).not_to be_assignable_to(t1)
      end

      it 'A hash of string is not assignable to struct with integer value' do
        t1 = struct_t({'foo' => integer_t, 'bar' => string_t})
        t2 = hash_t(string_t, string_t, range_t(2, 2))
        expect(t1.assignable?(t2)).to eql(false)
      end

      it 'A hash of with integer key is not assignable to struct with string key' do
        t1 = struct_t({'foo' => string_t, 'bar' => string_t})
        t2 = hash_t(integer_t, string_t, range_t(2, 2))
        expect(t1.assignable?(t2)).to eql(false)
      end
    end

    context 'for Callable, such that' do
      it 'Callable is not assignable to any disjunct type' do
        t = PCallableType::DEFAULT
        tested_types = all_types - [
          PCallableType,
          PAnyType,
          POptionalType,
          PNotUndefType]
        tested_types.each {|t2| expect(t).to_not be_assignable_to(t2::DEFAULT) }
      end

      it 'a callable with parameter is assignable to the default callable' do
        expect(callable_t(string_t)).to be_assignable_to(PCallableType::DEFAULT)
      end

      it 'the default callable is not assignable to a callable with parameter' do
        expect(PCallableType::DEFAULT).not_to be_assignable_to(callable_t(string_t))
      end

      it 'a callable with a return type is assignable to the default callable' do
        expect(callable_t([], string_t)).to be_assignable_to(PCallableType::DEFAULT)
      end

      it 'the default callable is not assignable to a callable with a return type' do
        expect(PCallableType::DEFAULT).not_to be_assignable_to(callable_t([],string_t))
      end

      it 'a callable with a return type Any is assignable to the default callable' do
        expect(callable_t([], any_t)).to be_assignable_to(PCallableType::DEFAULT)
      end

      it 'a callable with a return type Any is equal to a callable with the same parameters and no return type' do
        expect(callable_t([string_t], any_t)).to eql(callable_t(string_t))
      end

      it 'a callable with a return type different than Any is not equal to a callable with the same parameters and no return type' do
        expect(callable_t([string_t], string_t)).not_to eql(callable_t(string_t))
      end

      it 'a callable with a return type is assignable from another callable with an assignable return type' do
        expect(callable_t([], string_t)).to be_assignable_to(callable_t([], PScalarType::DEFAULT))
      end

      it 'a callable with a return type is not assignable from another callable unless the return type is assignable' do
        expect(callable_t([], string_t)).not_to be_assignable_to(callable_t([], integer_t))
      end
    end

    it 'should recognize mapped ruby types' do
      { Integer    => PIntegerType::DEFAULT,
        Float      => PFloatType::DEFAULT,
        Numeric    => PNumericType::DEFAULT,
        NilClass   => PUndefType::DEFAULT,
        TrueClass  => PBooleanType::DEFAULT,
        FalseClass => PBooleanType::DEFAULT,
        String     => PStringType::DEFAULT,
        Regexp     => PRegexpType::DEFAULT,
        Regexp     => PRegexpType::DEFAULT,
        Array      => TypeFactory.array_of_any,
        Hash       => TypeFactory.hash_of_any
      }.each do |ruby_type, puppet_type |
          expect(ruby_type).to be_assignable_to(puppet_type)
      end
    end

    context 'when dealing with integer ranges' do
      it 'should accept an equal range' do
        expect(calculator.assignable?(range_t(2,5), range_t(2,5))).to eq(true)
      end

      it 'should accept a narrower range' do
        expect(calculator.assignable?(range_t(2,10), range_t(3,5))).to eq(true)
      end

      it 'should reject a wider range' do
        expect(calculator.assignable?(range_t(3,5), range_t(2,10))).to eq(false)
      end

      it 'should reject a partially overlapping range' do
        expect(calculator.assignable?(range_t(3,5), range_t(2,4))).to eq(false)
        expect(calculator.assignable?(range_t(3,5), range_t(4,6))).to eq(false)
      end
    end

    context 'when dealing with patterns' do
      it 'should accept a string matching a pattern' do
        p_t = pattern_t('abc')
        p_s = string_t('XabcY')
        expect(calculator.assignable?(p_t, p_s)).to eq(true)
      end

      it 'should accept a regexp matching a pattern' do
        p_t = pattern_t(/abc/)
        p_s = string_t('XabcY')
        expect(calculator.assignable?(p_t, p_s)).to eq(true)
      end

      it 'should accept a pattern matching a pattern' do
        p_t = pattern_t(pattern_t('abc'))
        p_s = string_t('XabcY')
        expect(calculator.assignable?(p_t, p_s)).to eq(true)
      end

      it 'should accept a regexp matching a pattern' do
        p_t = pattern_t(regexp_t('abc'))
        p_s = string_t('XabcY')
        expect(calculator.assignable?(p_t, p_s)).to eq(true)
      end

      it 'should accept a string matching all patterns' do
        p_t = pattern_t('abc', 'ab', 'c')
        p_s = string_t('XabcY')
        expect(calculator.assignable?(p_t, p_s)).to eq(true)
      end

      it 'should accept multiple strings if they all match any patterns' do
        p_t = pattern_t('X', 'Y', 'abc')
        p_s = enum_t('Xa', 'aY', 'abc')
        expect(calculator.assignable?(p_t, p_s)).to eq(true)
      end

      it 'should reject a string not matching any patterns' do
        p_t = pattern_t('abc', 'ab', 'c')
        p_s = string_t('XqqqY')
        expect(calculator.assignable?(p_t, p_s)).to eq(false)
      end

      it 'should reject multiple strings if not all match any patterns' do
        p_t = pattern_t('abc', 'ab', 'c', 'q')
        p_s = enum_t('X', 'Y', 'Z')
        expect(calculator.assignable?(p_t, p_s)).to eq(false)
      end

      it 'should accept enum matching patterns as instanceof' do
        enum = enum_t('XS', 'S', 'M', 'L' 'XL', 'XXL')
        pattern = pattern_t('S', 'M', 'L')
        expect(calculator.assignable?(pattern, enum)).to  eq(true)
      end

      it 'pattern should accept a variant where all variants are acceptable' do
        pattern = pattern_t(/^\w+$/)
        expect(calculator.assignable?(pattern, variant_t(string_t('a'), string_t('b')))).to eq(true)
      end

      it 'pattern representing all patterns should accept any pattern' do
        expect(calculator.assignable?(pattern_t, pattern_t('a'))).to eq(true)
        expect(calculator.assignable?(pattern_t, pattern_t)).to eq(true)
      end

      it 'pattern representing all patterns should accept any enum' do
        expect(calculator.assignable?(pattern_t, enum_t('a'))).to eq(true)
        expect(calculator.assignable?(pattern_t, enum_t)).to eq(true)
      end

      it 'pattern representing all patterns should accept any string' do
        expect(calculator.assignable?(pattern_t, string_t('a'))).to eq(true)
        expect(calculator.assignable?(pattern_t, string_t)).to eq(true)
      end

    end

    context 'when dealing with enums' do
      it 'should accept a string with matching content' do
        expect(calculator.assignable?(enum_t('a', 'b'), string_t('a'))).to eq(true)
        expect(calculator.assignable?(enum_t('a', 'b'), string_t('b'))).to eq(true)
        expect(calculator.assignable?(enum_t('a', 'b'), string_t('c'))).to eq(false)
      end

      it 'should accept an enum with matching enum' do
        expect(calculator.assignable?(enum_t('a', 'b'), enum_t('a', 'b'))).to eq(true)
        expect(calculator.assignable?(enum_t('a', 'b'), enum_t('a'))).to eq(true)
        expect(calculator.assignable?(enum_t('a', 'b'), enum_t('c'))).to eq(false)
      end

      it 'non parameterized enum accepts any other enum but not the reverse' do
        expect(calculator.assignable?(enum_t, enum_t('a'))).to eq(true)
        expect(calculator.assignable?(enum_t('a'), enum_t)).to eq(false)
      end

      it 'enum should accept a variant where all variants are acceptable' do
        enum = enum_t('a', 'b')
        expect(calculator.assignable?(enum, variant_t(string_t('a'), string_t('b')))).to eq(true)
      end
    end

    context 'when dealing with string and enum combinations' do
      it 'should accept assigning any enum to unrestricted string' do
        expect(calculator.assignable?(string_t, enum_t('blue'))).to eq(true)
        expect(calculator.assignable?(string_t, enum_t('blue', 'red'))).to eq(true)
      end

      it 'should not accept assigning longer enum value to size restricted string' do
        expect(calculator.assignable?(constrained_string_t(range_t(2,2)), enum_t('a','blue'))).to eq(false)
      end

      it 'should accept assigning any string to empty enum' do
        expect(calculator.assignable?(enum_t, string_t)).to eq(true)
      end

      it 'should accept assigning empty enum to any string' do
        expect(calculator.assignable?(string_t, enum_t)).to eq(true)
      end

      it 'should not accept assigning empty enum to size constrained string' do
        expect(calculator.assignable?(constrained_string_t(range_t(2,2)), enum_t)).to eq(false)
      end
    end

    context 'when dealing with string/pattern/enum combinations' do
      it 'any string is equal to any enum is equal to any pattern' do
        expect(calculator.assignable?(string_t, enum_t)).to eq(true)
        expect(calculator.assignable?(string_t, pattern_t)).to eq(true)
        expect(calculator.assignable?(enum_t, string_t)).to eq(true)
        expect(calculator.assignable?(enum_t, pattern_t)).to eq(true)
        expect(calculator.assignable?(pattern_t, string_t)).to eq(true)
        expect(calculator.assignable?(pattern_t, enum_t)).to eq(true)
      end
    end

    context 'when dealing with tuples' do
      it 'matches empty tuples' do
        tuple1 = tuple_t
        tuple2 = tuple_t

        expect(calculator.assignable?(tuple1, tuple2)).to eq(true)
        expect(calculator.assignable?(tuple2, tuple1)).to eq(true)
      end

      it 'accepts an empty tuple as assignable to a tuple with a min size of 0' do
        tuple1 = constrained_tuple_t(range_t(0, :default))
        tuple2 = tuple_t()

        expect(calculator.assignable?(tuple1, tuple2)).to eq(true)
        expect(calculator.assignable?(tuple2, tuple1)).to eq(true)
      end

      it 'should accept matching tuples' do
        tuple1 = tuple_t(1,2)
        tuple2 = tuple_t(Integer,Integer)
        expect(calculator.assignable?(tuple1, tuple2)).to eq(true)
        expect(calculator.assignable?(tuple2, tuple1)).to eq(true)
      end

      it 'should accept matching tuples where one is more general than the other' do
        tuple1 = tuple_t(1,2)
        tuple2 = tuple_t(Numeric,Numeric)
        expect(calculator.assignable?(tuple1, tuple2)).to eq(false)
        expect(calculator.assignable?(tuple2, tuple1)).to eq(true)
      end

      it 'should accept ranged tuples' do
        tuple1 = constrained_tuple_t(range_t(5,5), 1)
        tuple2 = tuple_t(Integer,Integer, Integer, Integer, Integer)
        expect(calculator.assignable?(tuple1, tuple2)).to eq(true)
        expect(calculator.assignable?(tuple2, tuple1)).to eq(true)
      end

      it 'should reject ranged tuples when ranges does not match' do
        tuple1 = constrained_tuple_t(range_t(4, 5), 1)
        tuple2 = tuple_t(Integer,Integer, Integer, Integer, Integer)
        expect(calculator.assignable?(tuple1, tuple2)).to eq(true)
        expect(calculator.assignable?(tuple2, tuple1)).to eq(false)
      end

      it 'should reject ranged tuples when ranges does not match (using infinite upper bound)' do
        tuple1 = constrained_tuple_t(range_t(4, :default), 1)
        tuple2 = tuple_t(Integer,Integer, Integer, Integer, Integer)
        expect(calculator.assignable?(tuple1, tuple2)).to eq(true)
        expect(calculator.assignable?(tuple2, tuple1)).to eq(false)
      end

      it 'should accept matching tuples with optional entries by repeating last' do
        tuple1 = constrained_tuple_t(range_t(0, :default), 1,2)
        tuple2 = constrained_tuple_t(range_t(0, :default), Numeric,Numeric)
        expect(calculator.assignable?(tuple1, tuple2)).to eq(false)
        expect(calculator.assignable?(tuple2, tuple1)).to eq(true)
      end

      it 'should accept matching tuples with optional entries' do
        tuple1 = constrained_tuple_t(range_t(1, 3), Integer, Integer, String)
        array2 = array_t(Integer, range_t(2,2))
        expect(calculator.assignable?(tuple1, array2)).to eq(true)
        tuple1 = constrained_tuple_t(range_t(3, 3), tuple1.types)
        expect(calculator.assignable?(tuple1, array2)).to eq(false)
      end

      it 'should accept matching array' do
        tuple1 = tuple_t(1,2)
        array = array_t(Integer, range_t(2, 2))
        expect(calculator.assignable?(tuple1, array)).to eq(true)
        expect(calculator.assignable?(array, tuple1)).to eq(true)
      end

      it 'should accept empty array when tuple allows min of 0' do
        tuple1 = constrained_tuple_t(range_t(0, 1), Integer)
        array = array_t(unit_t, range_t(0, 0))
        expect(calculator.assignable?(tuple1, array)).to eq(true)
        expect(calculator.assignable?(array, tuple1)).to eq(false)
      end
    end

    context 'when dealing with structs' do
      it 'should accept matching structs' do
        struct1 = struct_t({'a'=>Integer, 'b'=>Integer})
        struct2 = struct_t({'a'=>Integer, 'b'=>Integer})
        expect(calculator.assignable?(struct1, struct2)).to eq(true)
        expect(calculator.assignable?(struct2, struct1)).to eq(true)
      end

      it 'should accept matching structs with less elements when unmatched elements are optional' do
        struct1 = struct_t({'a'=>Integer, 'b'=>Integer, 'c'=>optional_t(Integer)})
        struct2 = struct_t({'a'=>Integer, 'b'=>Integer})
        expect(calculator.assignable?(struct1, struct2)).to eq(true)
      end

      it 'should reject matching structs with more elements even if excess elements are optional' do
        struct1 = struct_t({'a'=>Integer, 'b'=>Integer})
        struct2 = struct_t({'a'=>Integer, 'b'=>Integer, 'c'=>optional_t(Integer)})
        expect(calculator.assignable?(struct1, struct2)).to eq(false)
      end

      it 'should accept matching structs where one is more general than the other with respect to optional' do
        struct1 = struct_t({'a'=>Integer, 'b'=>Integer, 'c'=>optional_t(Integer)})
        struct2 = struct_t({'a'=>Integer, 'b'=>Integer, 'c'=>Integer})
        expect(calculator.assignable?(struct1, struct2)).to eq(true)
      end

      it 'should reject matching structs where one is more special than the other with respect to optional' do
        struct1 = struct_t({'a'=>Integer, 'b'=>Integer, 'c'=>Integer})
        struct2 = struct_t({'a'=>Integer, 'b'=>Integer, 'c'=>optional_t(Integer)})
        expect(calculator.assignable?(struct1, struct2)).to eq(false)
      end

      it 'should accept matching structs where one is more general than the other' do
        struct1 = struct_t({'a'=>Integer, 'b'=>Integer})
        struct2 = struct_t({'a'=>Numeric, 'b'=>Numeric})
        expect(calculator.assignable?(struct1, struct2)).to eq(false)
        expect(calculator.assignable?(struct2, struct1)).to eq(true)
      end

      it 'should accept matching hash' do
        struct1 = struct_t({'a'=>Integer, 'b'=>Integer})
        non_empty_string = constrained_string_t(range_t(1, nil))
        hsh = hash_t(non_empty_string, Integer, range_t(2,2))
        expect(calculator.assignable?(struct1, hsh)).to eq(true)
        expect(calculator.assignable?(hsh, struct1)).to eq(true)
      end

      it 'should accept empty hash with key_type unit' do
        struct1 = struct_t({'a'=>optional_t(Integer)})
        hsh = hash_t(unit_t, unit_t, range_t(0, 0))
        expect(calculator.assignable?(struct1, hsh)).to eq(true)
      end
    end

    it 'should recognize ruby type inheritance' do
      class Foo
      end

      class Bar < Foo
      end

      fooType = calculator.infer(Foo.new)
      barType = calculator.infer(Bar.new)

      expect(calculator.assignable?(fooType, fooType)).to eq(true)
      expect(calculator.assignable?(Foo, fooType)).to eq(true)

      expect(calculator.assignable?(fooType, barType)).to eq(true)
      expect(calculator.assignable?(Foo, barType)).to eq(true)

      expect(calculator.assignable?(barType, fooType)).to eq(false)
      expect(calculator.assignable?(Bar, fooType)).to eq(false)
    end

    it 'should allow host class with same name' do
      hc1 = TypeFactory.host_class('the_name')
      hc2 = TypeFactory.host_class('the_name')
      expect(calculator.assignable?(hc1, hc2)).to eq(true)
    end

    it 'should allow host class with name assigned to hostclass without name' do
      hc1 = TypeFactory.host_class
      hc2 = TypeFactory.host_class('the_name')
      expect(calculator.assignable?(hc1, hc2)).to eq(true)
    end

    it 'should reject host classes with different names' do
      hc1 = TypeFactory.host_class('the_name')
      hc2 = TypeFactory.host_class('another_name')
      expect(calculator.assignable?(hc1, hc2)).to eq(false)
    end

    it 'should reject host classes without name assigned to host class with name' do
      hc1 = TypeFactory.host_class('the_name')
      hc2 = TypeFactory.host_class
      expect(calculator.assignable?(hc1, hc2)).to eq(false)
    end

    it 'should allow resource with same type_name and title' do
      r1 = TypeFactory.resource('file', 'foo')
      r2 = TypeFactory.resource('file', 'foo')
      expect(calculator.assignable?(r1, r2)).to eq(true)
    end

    it 'should allow more specific resource assignment' do
      r1 = TypeFactory.resource
      r2 = TypeFactory.resource('file')
      expect(calculator.assignable?(r1, r2)).to eq(true)
      r2 = TypeFactory.resource('file', '/tmp/foo')
      expect(calculator.assignable?(r1, r2)).to eq(true)
      r1 = TypeFactory.resource('file')
      expect(calculator.assignable?(r1, r2)).to eq(true)
    end

    it 'should reject less specific resource assignment' do
      r1 = TypeFactory.resource('file', '/tmp/foo')
      r2 = TypeFactory.resource('file')
      expect(calculator.assignable?(r1, r2)).to eq(false)
      r2 = TypeFactory.resource
      expect(calculator.assignable?(r1, r2)).to eq(false)
    end

    context 'for TypeAlias, such that' do
      let!(:parser) { TypeParser.singleton }

      it 'it is assignable to the type that it is an alias for' do
        t = type_alias_t('Alias', 'Integer').resolve(nil)
        expect(calculator.assignable?(integer_t, t)).to be_truthy
      end

      it 'the type that it is an alias for is assignable to it' do
        t = type_alias_t('Alias', 'Integer').resolve(nil)
        expect(calculator.assignable?(t, integer_t)).to be_truthy
      end

      it 'a recursive alias can be assignable from a conformant type with any depth' do
        scope = {}

        t = type_alias_t('Tree', 'Hash[String,Variant[String,Tree]]')
        loader = double
        expect(loader).to receive(:load).with(:type, 'tree').and_return(t)

        expect(Adapters::LoaderAdapter).to receive(:loader_for_model_object).at_least(:once).and_return(loader)

        t.resolve(scope)
        expect(calculator.assignable?(t, parser.parse('Hash[String,Variant[String,Hash[String,Variant[String,String]]]]'))).to be_truthy
      end


      it 'similar recursive aliases are assignable' do
        scope = {}

        t1 = type_alias_t('Tree1', 'Hash[String,Variant[String,Tree1]]')
        t2 = type_alias_t('Tree2', 'Hash[String,Variant[String,Tree2]]')
        loader = double
        expect(loader).to receive(:load).with(:type, 'tree1').and_return(t1)
        expect(loader).to receive(:load).with(:type, 'tree2').and_return(t2)

        expect(Adapters::LoaderAdapter).to receive(:loader_for_model_object).at_least(:once).and_return(loader)

        t1.resolve(scope)
        t2.resolve(scope)
        expect(calculator.assignable?(t1, t2)).to be_truthy
      end

      it 'crossing recursive aliases are assignable' do
        t1 = type_alias_t('Tree1', 'Hash[String,Variant[String,Tree2]]')
        t2 = type_alias_t('Tree2', 'Hash[String,Variant[String,Tree1]]')
        loader = double
        expect(loader).to receive(:load).with(:type, 'tree1').and_return(t1)
        expect(loader).to receive(:load).with(:type, 'tree2').and_return(t2)

        expect(Adapters::LoaderAdapter).to receive(:loader_for_model_object).at_least(:once).and_return(loader)

        t1.resolve(loader)
        t2.resolve(loader)
        expect(calculator.assignable?(t1, t2)).to be_truthy
      end

      it 'Type[T] is assignable to Type[AT] when AT is an alias for T' do
        scope = {}

        ta = type_alias_t('PositiveInteger', 'Integer[0,default]')
        loader = double
        expect(loader).to receive(:load).with(:type, 'positiveinteger').and_return(ta)
        expect(Adapters::LoaderAdapter).to receive(:loader_for_model_object).at_least(:once).and_return(loader)

        t1 = type_t(range_t(0, :default))
        t2 = parser.parse('Type[PositiveInteger]', scope)
        expect(calculator.assignable?(t2, t1)).to be_truthy
      end

      it 'Type[T] is assignable to AT when AT is an alias for Type[T]' do
        scope = {}

        ta = type_alias_t('PositiveIntegerType', 'Type[Integer[0,default]]')
        loader = double
        expect(loader).to receive(:load).with(:type, 'positiveintegertype').and_return(ta)
        expect(Adapters::LoaderAdapter).to receive(:loader_for_model_object).at_least(:once).and_return(loader)

        t1 = type_t(range_t(0, :default))
        t2 = parser.parse('PositiveIntegerType', scope)
        expect(calculator.assignable?(t2, t1)).to be_truthy
      end

      it 'Type[Type[T]] is assignable to Type[Type[AT]] when AT is an alias for T' do
        scope = {}

        ta = type_alias_t('PositiveInteger', 'Integer[0,default]')
        loader = double
        expect(loader).to receive(:load).with(:type, 'positiveinteger').and_return(ta)
        expect(Adapters::LoaderAdapter).to receive(:loader_for_model_object).at_least(:once).and_return(loader)

        t1 = type_t(type_t(range_t(0, :default)))
        t2 = parser.parse('Type[Type[PositiveInteger]]', scope)
        expect(calculator.assignable?(t2, t1)).to be_truthy
      end

      it 'Type[Type[T]] is assignable to Type[AT] when AT is an alias for Type[T]' do
        scope = {}

        ta = type_alias_t('PositiveIntegerType', 'Type[Integer[0,default]]')
        loader = double
        expect(loader).to receive(:load).with(:type, 'positiveintegertype').and_return(ta)
        expect(Adapters::LoaderAdapter).to receive(:loader_for_model_object).at_least(:once).and_return(loader)

        t1 = type_t(type_t(range_t(0, :default)))
        t2 = parser.parse('Type[PositiveIntegerType]', scope)
        expect(calculator.assignable?(t2, t1)).to be_truthy
      end

      it 'An alias for a Type that describes an Iterable instance is assignable to Iterable' do
        t = type_alias_t('MyType', 'Enum[a,b]').resolve(nil)

        # True because String is iterable and an instance of Enum is a String
        expect(calculator.assignable?(iterable_t, t)).to be_truthy
      end
    end
  end

  context 'when testing if x is instance of type t' do
    include_context 'types_setup'

    it 'should consider undef to be instance of Any, NilType, and optional' do
      expect(calculator.instance?(PUndefType::DEFAULT, nil)).to    eq(true)
      expect(calculator.instance?(PAnyType::DEFAULT, nil)).to eq(true)
      expect(calculator.instance?(POptionalType::DEFAULT, nil)).to eq(true)
    end

    it 'all types should be (ruby) instance of PAnyType' do
      all_types.each do |t|
        expect(t::DEFAULT.is_a?(PAnyType)).to eq(true)
      end
    end

    it "should infer :undef to be Undef" do
      expect(calculator.infer(:undef)).to be_assignable_to(undef_t)
    end

    it "should not consider :default to be instance of Runtime['ruby', 'Symbol]" do
      expect(calculator.instance?(PRuntimeType.new(:ruby, 'Symbol'), :default)).to eq(false)
    end

    it "should not consider :undef to be instance of Runtime['ruby', 'Symbol]" do
      expect(calculator.instance?(PRuntimeType.new(:ruby, 'Symbol'), :undef)).to eq(false)
    end

    it 'should consider :undef to be instance of an Optional type' do
      expect(calculator.instance?(POptionalType::DEFAULT, :undef)).to eq(true)
    end

    it 'should not consider undef to be an instance of any other type than Any, Undef, Optional, and Init' do
      types_to_test = all_types - [
        PAnyType,
        PUndefType,
        POptionalType,
        PInitType
        ]

      types_to_test.each {|t| expect(calculator.instance?(t::DEFAULT, nil)).to eq(false) }
      types_to_test.each {|t| expect(calculator.instance?(t::DEFAULT, :undef)).to eq(false) }
    end

    it 'should consider default to be instance of Default and Any' do
      expect(calculator.instance?(PDefaultType::DEFAULT, :default)).to eq(true)
      expect(calculator.instance?(PAnyType::DEFAULT, :default)).to eq(true)
    end

    it 'should not consider "default" to be an instance of anything but Default, Init, NotUndef, and Any' do
      types_to_test = all_types - [
        PAnyType,
        PNotUndefType,
        PDefaultType,
        PInitType,
        ]

      types_to_test.each {|t| expect(calculator.instance?(t::DEFAULT, :default)).to eq(false) }
    end

    it 'should consider integer instanceof PIntegerType' do
      expect(calculator.instance?(PIntegerType::DEFAULT, 1)).to eq(true)
    end

    it 'should consider integer instanceof Integer' do
      expect(calculator.instance?(Integer, 1)).to eq(true)
    end

    it 'should consider integer in range' do
      range = range_t(0,10)
      expect(calculator.instance?(range, 1)).to eq(true)
      expect(calculator.instance?(range, 10)).to eq(true)
      expect(calculator.instance?(range, -1)).to eq(false)
      expect(calculator.instance?(range, 11)).to eq(false)
    end

    it 'should consider string in length range' do
      range = constrained_string_t(range_t(1,3))
      expect(calculator.instance?(range, 'a')).to    eq(true)
      expect(calculator.instance?(range, 'abc')).to  eq(true)
      expect(calculator.instance?(range, '')).to     eq(false)
      expect(calculator.instance?(range, 'abcd')).to eq(false)
    end

    it 'should consider string values' do
      string = string_t('a')
      expect(calculator.instance?(string, 'a')).to eq(true)
      expect(calculator.instance?(string, 'c')).to eq(false)
    end

    it 'should consider array in length range' do
      range = array_t(integer_t, range_t(1,3))
      expect(calculator.instance?(range, [1])).to    eq(true)
      expect(calculator.instance?(range, [1,2,3])).to  eq(true)
      expect(calculator.instance?(range, [])).to     eq(false)
      expect(calculator.instance?(range, [1,2,3,4])).to eq(false)
    end

    it 'should consider hash in length range' do
      range = hash_t(integer_t, integer_t, range_t(1,2))
      expect(calculator.instance?(range, {1=>1})).to             eq(true)
      expect(calculator.instance?(range, {1=>1, 2=>2})).to       eq(true)
      expect(calculator.instance?(range, {})).to                 eq(false)
      expect(calculator.instance?(range, {1=>1, 2=>2, 3=>3})).to eq(false)
    end

    it 'should consider collection in length range for array ' do
      range = collection_t(range_t(1,3))
      expect(calculator.instance?(range, [1])).to    eq(true)
      expect(calculator.instance?(range, [1,2,3])).to  eq(true)
      expect(calculator.instance?(range, [])).to     eq(false)
      expect(calculator.instance?(range, [1,2,3,4])).to eq(false)
    end

    it 'should consider collection in length range for hash' do
      range = collection_t(range_t(1,2))
      expect(calculator.instance?(range, {1=>1})).to             eq(true)
      expect(calculator.instance?(range, {1=>1, 2=>2})).to       eq(true)
      expect(calculator.instance?(range, {})).to                 eq(false)
      expect(calculator.instance?(range, {1=>1, 2=>2, 3=>3})).to eq(false)
    end

    it 'should consider string matching enum as instanceof' do
      enum = enum_t('XS', 'S', 'M', 'L', 'XL', '0')
      expect(calculator.instance?(enum, 'XS')).to  eq(true)
      expect(calculator.instance?(enum, 'S')).to   eq(true)
      expect(calculator.instance?(enum, 'XXL')).to eq(false)
      expect(calculator.instance?(enum, '')).to    eq(false)
      expect(calculator.instance?(enum, '0')).to   eq(true)
      expect(calculator.instance?(enum, 0)).to     eq(false)
    end

    it 'should consider array[string] as instance of Array[Enum] when strings are instance of Enum' do
      enum = enum_t('XS', 'S', 'M', 'L', 'XL', '0')
      array = array_t(enum)
      expect(calculator.instance?(array, ['XS', 'S', 'XL'])).to  eq(true)
      expect(calculator.instance?(array, ['XS', 'S', 'XXL'])).to eq(false)
    end

    it 'should consider array[mixed] as instance of Variant[mixed] when mixed types are listed in Variant' do
      enum = enum_t('XS', 'S', 'M', 'L', 'XL')
      sizes = range_t(30, 50)
      array = array_t(variant_t(enum, sizes))
      expect(calculator.instance?(array, ['XS', 'S', 30, 50])).to  eq(true)
      expect(calculator.instance?(array, ['XS', 'S', 'XXL'])).to   eq(false)
      expect(calculator.instance?(array, ['XS', 'S', 29])).to      eq(false)
    end

    it 'should consider array[seq] as instance of Tuple[seq] when elements of seq are instance of' do
      tuple = tuple_t(Integer, String, Float)
      expect(calculator.instance?(tuple, [1, 'a', 3.14])).to       eq(true)
      expect(calculator.instance?(tuple, [1.2, 'a', 3.14])).to     eq(false)
      expect(calculator.instance?(tuple, [1, 1, 3.14])).to         eq(false)
      expect(calculator.instance?(tuple, [1, 'a', 1])).to          eq(false)
    end

    it 'should not consider ProcessOutput objects as instanceof PScalarDataType' do
      object = Puppet::Util::Execution::ProcessOutput.new('object', 0)
      
      expect(calculator.instance?(PScalarDataType::DEFAULT, object)).to eq(false)
    end

    context 'and t is Struct' do
      it 'should consider hash[cont] as instance of Struct[cont-t]' do
        struct = struct_t({'a'=>Integer, 'b'=>String, 'c'=>Float})
        expect(calculator.instance?(struct, {'a'=>1, 'b'=>'a', 'c'=>3.14})).to       eq(true)
        expect(calculator.instance?(struct, {'a'=>1.2, 'b'=>'a', 'c'=>3.14})).to     eq(false)
        expect(calculator.instance?(struct, {'a'=>1, 'b'=>1, 'c'=>3.14})).to         eq(false)
        expect(calculator.instance?(struct, {'a'=>1, 'b'=>'a', 'c'=>1})).to          eq(false)
      end

      it 'should consider empty hash as instance of Struct[x=>Optional[String]]' do
        struct = struct_t({'a'=>optional_t(String)})
        expect(calculator.instance?(struct, {})).to eq(true)
      end

      it 'should consider hash[cont] as instance of Struct[cont-t,optionals]' do
        struct = struct_t({'a'=>Integer, 'b'=>String, 'c'=>optional_t(Float)})
        expect(calculator.instance?(struct, {'a'=>1, 'b'=>'a'})).to eq(true)
      end

      it 'should consider hash[cont] as instance of Struct[cont-t,variants with optionals]' do
        struct = struct_t({'a'=>Integer, 'b'=>String, 'c'=>variant_t(String, optional_t(Float))})
        expect(calculator.instance?(struct, {'a'=>1, 'b'=>'a'})).to eq(true)
      end

      it 'should not consider hash[cont,cont2] as instance of Struct[cont-t]' do
        struct = struct_t({'a'=>Integer, 'b'=>String})
        expect(calculator.instance?(struct, {'a'=>1, 'b'=>'a', 'c'=>'x'})).to eq(false)
      end

      it 'should not consider hash[cont,cont2] as instance of Struct[cont-t,optional[cont3-t]' do
        struct = struct_t({'a'=>Integer, 'b'=>String, 'c'=>optional_t(Float)})
        expect(calculator.instance?(struct, {'a'=>1, 'b'=>'a', 'c'=>'x'})).to eq(false)
      end

      it 'should consider nil to be a valid element value' do
        struct = struct_t({not_undef_t('a') => any_t, 'b'=>String})
        expect(calculator.instance?(struct, {'a'=>nil , 'b'=>'a'})).to eq(true)
      end

      it 'should consider nil to be a valid element value but subject to value type' do
        struct = struct_t({not_undef_t('a') => String, 'b'=>String})
        expect(calculator.instance?(struct, {'a'=>nil , 'b'=>'a'})).to eq(false)
      end

      it 'should consider nil to be a valid element value but subject to value type even when key is optional' do
        struct = struct_t({optional_t('a') => String, 'b'=>String})
        expect(calculator.instance?(struct, {'a'=>nil , 'b'=>'a'})).to eq(false)
      end

      it 'should consider a hash where optional key is missing as assignable even if value of optional key is required' do
        struct = struct_t({optional_t('a') => String, 'b'=>String})
        expect(calculator.instance?(struct, {'b'=>'a'})).to eq(true)
      end
    end

    context 'and t is Data' do
      it 'undef should be considered instance of Data' do
        expect(calculator.instance?(data_t, nil)).to eq(true)
      end

      it 'other symbols should not be considered instance of Data' do
        expect(calculator.instance?(data_t, :love)).to eq(false)
      end

      it 'an empty array should be considered instance of Data' do
        expect(calculator.instance?(data_t, [])).to eq(true)
      end

      it 'an empty hash should be considered instance of Data' do
        expect(calculator.instance?(data_t, {})).to eq(true)
      end

      it 'a hash with nil/undef data should be considered instance of Data' do
        expect(calculator.instance?(data_t, {'a' => nil})).to eq(true)
      end

      it 'a hash with nil/default key should not considered instance of Data' do
        expect(calculator.instance?(data_t, {nil => 10})).to eq(false)
        expect(calculator.instance?(data_t, {:default => 10})).to eq(false)
      end

      it 'an array with nil entries should be considered instance of Data' do
        expect(calculator.instance?(data_t, [nil])).to eq(true)
      end

      it 'an array with nil + data entries should be considered instance of Data' do
        expect(calculator.instance?(data_t, [1, nil, 'a'])).to eq(true)
      end
    end

    context 'and t is something Callable' do

      it 'a Closure should be considered a Callable' do
        factory = Model::Factory
        params = [factory.PARAM('a')]
        the_block = factory.LAMBDA(params,factory.literal(42), nil).model
        the_closure = Evaluator::Closure::Dynamic.new(:fake_evaluator, the_block, :fake_scope)
        expect(calculator.instance?(all_callables_t, the_closure)).to be_truthy
        expect(calculator.instance?(callable_t(any_t), the_closure)).to be_truthy
        expect(calculator.instance?(callable_t(any_t, any_t), the_closure)).to be_falsey
      end

      it 'a Function instance should be considered a Callable' do
        fc = Puppet::Functions.create_function(:foo) do
          dispatch :foo do
            param 'String', :a
          end

          def foo(a)
            a
          end
        end
        f = fc.new(:closure_scope, :loader)
        # Any callable
        expect(calculator.instance?(all_callables_t, f)).to be_truthy
        # Callable[String]
        expect(calculator.instance?(callable_t(String), f)).to be_truthy
      end
    end

    context 'and t is a TypeAlias' do
      let!(:parser) { TypeParser.singleton }

      it 'should consider x an instance of the aliased simple type' do
        t = type_alias_t('Alias', 'Integer').resolve(nil)
        expect(calculator.instance?(t, 15)).to be_truthy
      end

      it 'should consider x an instance of the aliased parameterized type' do
        t = type_alias_t('Alias', 'Integer[0,20]').resolve(nil)
        expect(calculator.instance?(t, 15)).to be_truthy
      end

      it 'should consider t an instance of Iterable when aliased type is Iterable' do
        t = type_alias_t('Alias', 'Enum[a, b]').resolve(nil)
        expect(calculator.instance?(iterable_t, t)).to be_truthy
      end

      it 'should consider x an instance of the aliased type that uses self recursion' do
        t = type_alias_t('Tree', 'Hash[String,Variant[String,Tree]]')
        loader = double
        expect(loader).to receive(:load).with(:type, 'tree').and_return(t)

        expect(Adapters::LoaderAdapter).to receive(:loader_for_model_object).at_least(:once).and_return(loader)

        t.resolve(loader)
        expect(calculator.instance?(t, {'a'=>{'aa'=>{'aaa'=>'aaaa'}}, 'b'=>'bb'})).to be_truthy
      end

      it 'should consider x an instance of the aliased type that uses contains an alias that causes self recursion' do
        t1 = type_alias_t('Tree', 'Hash[String,Variant[String,OtherTree]]')
        t2 = type_alias_t('OtherTree', 'Hash[String,Tree]')
        loader = double
        expect(loader).to receive(:load).with(:type, 'tree').and_return(t1)
        expect(loader).to receive(:load).with(:type, 'othertree').and_return(t2)

        expect(Adapters::LoaderAdapter).to receive(:loader_for_model_object).at_least(:once).and_return(loader)

        t1.resolve(loader)
        expect(calculator.instance?(t1, {'a'=>{'aa'=>{'aaa'=>'aaaa'}}, 'b'=>'bb'})).to be_truthy
      end
    end
  end

  context 'when converting a ruby class' do
    it 'should yield \'PIntegerType\' for Integer' do
      expect(calculator.type(Integer).class).to eq(PIntegerType)
    end

    it 'should yield \'PFloatType\' for Float' do
      expect(calculator.type(Float).class).to eq(PFloatType)
    end

    it 'should yield \'PBooleanType\' for FalseClass and TrueClass' do
      [FalseClass,TrueClass].each do |c|
        expect(calculator.type(c).class).to eq(PBooleanType)
      end
    end

    it 'should yield \'PUndefType\' for NilClass' do
      expect(calculator.type(NilClass).class).to eq(PUndefType)
    end

    it 'should yield \'PStringType\' for String' do
      expect(calculator.type(String).class).to eq(PStringType)
    end

    it 'should yield \'PRegexpType\' for Regexp' do
      expect(calculator.type(Regexp).class).to eq(PRegexpType)
    end

    it 'should yield \'PArrayType[PAnyType]\' for Array' do
      t = calculator.type(Array)
      expect(t.class).to eq(PArrayType)
      expect(t.element_type.class).to eq(PAnyType)
    end

    it 'should yield \'PHashType[PAnyType,PAnyType]\' for Hash' do
      t = calculator.type(Hash)
      expect(t.class).to eq(PHashType)
      expect(t.key_type.class).to eq(PAnyType)
      expect(t.value_type.class).to eq(PAnyType)
    end

    it 'type should yield \'PRuntimeType[ruby,Rational]\' for Rational' do
      t = calculator.type(Rational)
      expect(t.class).to eq(PRuntimeType)
      expect(t.runtime).to eq(:ruby)
      expect(t.runtime_type_name).to eq('Rational')
    end

    it 'infer should yield \'PRuntimeType[ruby,Rational]\' for Rational instance' do
      t = calculator.infer(Rational(2, 3))
      expect(t.class).to eq(PRuntimeType)
      expect(t.runtime).to eq(:ruby)
      expect(t.runtime_type_name).to eq('Rational')
    end
  end

  context 'when processing meta type' do
    it 'should infer PTypeType as the type of all other types' do
      ptype = PTypeType
      expect(calculator.infer(PUndefType::DEFAULT     ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PScalarType::DEFAULT    ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PScalarDataType::DEFAULT).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PStringType::DEFAULT    ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PNumericType::DEFAULT   ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PIntegerType::DEFAULT   ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PFloatType::DEFAULT     ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PRegexpType::DEFAULT    ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PBooleanType::DEFAULT   ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PCollectionType::DEFAULT).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PArrayType::DEFAULT     ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PHashType::DEFAULT      ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PIterableType::DEFAULT  ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PRuntimeType::DEFAULT   ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PClassType::DEFAULT ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PResourceType::DEFAULT  ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PEnumType::DEFAULT      ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PPatternType::DEFAULT   ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PVariantType::DEFAULT   ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PTupleType::DEFAULT     ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(POptionalType::DEFAULT  ).is_a?(ptype)).to eq(true)
      expect(calculator.infer(PCallableType::DEFAULT  ).is_a?(ptype)).to eq(true)
    end

    it 'should infer PTypeType as the type of all other types' do
      expect(calculator.infer(PUndefType::DEFAULT     ).to_s).to eq('Type[Undef]')
      expect(calculator.infer(PScalarType::DEFAULT    ).to_s).to eq('Type[Scalar]')
      expect(calculator.infer(PScalarDataType::DEFAULT).to_s).to eq('Type[ScalarData]')
      expect(calculator.infer(PStringType::DEFAULT    ).to_s).to eq('Type[String]')
      expect(calculator.infer(PNumericType::DEFAULT   ).to_s).to eq('Type[Numeric]')
      expect(calculator.infer(PIntegerType::DEFAULT   ).to_s).to eq('Type[Integer]')
      expect(calculator.infer(PFloatType::DEFAULT     ).to_s).to eq('Type[Float]')
      expect(calculator.infer(PRegexpType::DEFAULT    ).to_s).to eq('Type[Regexp]')
      expect(calculator.infer(PBooleanType::DEFAULT   ).to_s).to eq('Type[Boolean]')
      expect(calculator.infer(PCollectionType::DEFAULT).to_s).to eq('Type[Collection]')
      expect(calculator.infer(PArrayType::DEFAULT     ).to_s).to eq('Type[Array]')
      expect(calculator.infer(PHashType::DEFAULT      ).to_s).to eq('Type[Hash]')
      expect(calculator.infer(PIterableType::DEFAULT  ).to_s).to eq('Type[Iterable]')
      expect(calculator.infer(PRuntimeType::DEFAULT   ).to_s).to eq('Type[Runtime]')
      expect(calculator.infer(PClassType::DEFAULT ).to_s).to eq('Type[Class]')
      expect(calculator.infer(PResourceType::DEFAULT  ).to_s).to eq('Type[Resource]')
      expect(calculator.infer(PEnumType::DEFAULT      ).to_s).to eq('Type[Enum]')
      expect(calculator.infer(PVariantType::DEFAULT   ).to_s).to eq('Type[Variant]')
      expect(calculator.infer(PPatternType::DEFAULT   ).to_s).to eq('Type[Pattern]')
      expect(calculator.infer(PTupleType::DEFAULT     ).to_s).to eq('Type[Tuple]')
      expect(calculator.infer(POptionalType::DEFAULT  ).to_s).to eq('Type[Optional]')
      expect(calculator.infer(PCallableType::DEFAULT  ).to_s).to eq('Type[Callable]')

      expect(calculator.infer(PResourceType.new('foo::fee::fum')).to_s).to eq('Type[Foo::Fee::Fum]')
      expect(calculator.infer(PResourceType.new('foo::fee::fum')).to_s).to eq('Type[Foo::Fee::Fum]')
      expect(calculator.infer(PResourceType.new('Foo::Fee::Fum')).to_s).to eq('Type[Foo::Fee::Fum]')
    end

    it "computes the common type of PTypeType's type parameter" do
      int_t    = PIntegerType::DEFAULT
      string_t = PStringType::DEFAULT
      expect(calculator.infer([int_t]).to_s).to eq('Array[Type[Integer], 1, 1]')
      expect(calculator.infer([int_t, string_t]).to_s).to eq('Array[Type[ScalarData], 2, 2]')
    end

    it 'should infer PTypeType as the type of ruby classes' do
      class Foo
      end
      [Object, Numeric, Integer, Float, String, Regexp, Array, Hash, Foo].each do |c|
        expect(calculator.infer(c).is_a?(PTypeType)).to eq(true)
      end
    end

    it 'should infer PTypeType as the type of PTypeType (meta regression short-circuit)' do
      expect(calculator.infer(PTypeType::DEFAULT).is_a?(PTypeType)).to eq(true)
    end

    it 'computes instance? to be true if parameterized and type match' do
      int_t    = PIntegerType::DEFAULT
      type_t   = TypeFactory.type_type(int_t)
      type_type_t   = TypeFactory.type_type(type_t)
      expect(calculator.instance?(type_type_t, type_t)).to eq(true)
    end

    it 'computes instance? to be false if parameterized and type do not match' do
      int_t    = PIntegerType::DEFAULT
      string_t = PStringType::DEFAULT
      type_t   = TypeFactory.type_type(int_t)
      type_t2   = TypeFactory.type_type(string_t)
      type_type_t   = TypeFactory.type_type(type_t)
      # i.e. Type[Integer] =~ Type[Type[Integer]] # false
      expect(calculator.instance?(type_type_t, type_t2)).to eq(false)
    end

    it 'computes instance? to be true if unparameterized and matched against a type[?]' do
      int_t    = PIntegerType::DEFAULT
      type_t   = TypeFactory.type_type(int_t)
      expect(calculator.instance?(PTypeType::DEFAULT, type_t)).to eq(true)
    end
  end

  context 'when asking for an iterable ' do
    it 'should produce an iterable for an Integer range that is finite' do
      t = PIntegerType.new(1, 10)
      expect(calculator.iterable(t).respond_to?(:each)).to eq(true)
    end

    it 'should not produce an iterable for an Integer range that has an infinite side' do
      t = PIntegerType.new(nil, 10)
      expect(calculator.iterable(t)).to eq(nil)

      t = PIntegerType.new(1, nil)
      expect(calculator.iterable(t)).to eq(nil)
    end

    it 'all but Integer range are not iterable' do
      [Object, Numeric, Float, String, Regexp, Array, Hash].each do |t|
        expect(calculator.iterable(calculator.type(t))).to eq(nil)
      end
    end

    it 'should produce an iterable for a type alias of an Iterable type' do
      t = PTypeAliasType.new('MyAlias', nil, PIntegerType.new(1, 10))
      expect(calculator.iterable(t).respond_to?(:each)).to eq(true)
    end
  end

  context 'when dealing with different types of inference' do
    it 'an instance specific inference is produced by infer' do
      expect(calculator.infer(['a','b']).element_type.values).to eq(['a', 'b'])
    end

    it 'a generic inference is produced using infer_generic' do
      expect(calculator.infer_generic(['a','b']).element_type).to eql(string_t(range_t(1,1)))
    end

    it 'a generic result is created by generalize given an instance specific result for an Array' do
      generic = calculator.infer(['a','b'])
      expect(generic.element_type.values).to eq(['a','b'])
      generic = generic.generalize
      expect(generic.element_type).to eql(string_t(range_t(1,1)))
    end

    it 'a generic result is created by generalize given an instance specific result for a Hash' do
      generic = calculator.infer({'a' =>1,'bcd' => 2})
      expect(generic.key_type.values.sort).to eq(['a', 'bcd'])
      expect(generic.value_type.from).to eq(1)
      expect(generic.value_type.to).to eq(2)
      generic = generic.generalize
      expect(generic.key_type.size_type).to eq(range_t(1,3))
      expect(generic.value_type.from).to eq(nil)
      expect(generic.value_type.to).to eq(nil)
    end

    it 'ensures that Struct key types are not generalized' do
      generic = struct_t({'a' => any_t}).generalize
      expect(generic.to_s).to eq("Struct[{'a' => Any}]")
      generic = struct_t({not_undef_t('a') => any_t}).generalize
      expect(generic.to_s).to eq("Struct[{NotUndef['a'] => Any}]")
      generic = struct_t({optional_t('a') => string_t}).generalize
      expect(generic.to_s).to eq("Struct[{Optional['a'] => String}]")
    end

    it 'ensures that Struct value types are generalized' do
      generic = struct_t({'a' => range_t(1, 3)}).generalize
      expect(generic.to_s).to eq("Struct[{'a' => Integer}]")
    end

    it "does not reduce by combining types when using infer_set" do
      element_type = calculator.infer(['a','b',1,2]).element_type
      expect(element_type.class).to eq(PScalarDataType)
      inferred_type = calculator.infer_set(['a','b',1,2])
      expect(inferred_type.class).to eq(PTupleType)
      element_types = inferred_type.types
      expect(element_types[0].class).to eq(PStringType)
      expect(element_types[1].class).to eq(PStringType)
      expect(element_types[2].class).to eq(PIntegerType)
      expect(element_types[3].class).to eq(PIntegerType)
    end

    it 'does not reduce by combining types when using infer_set and values are undef' do
      element_type = calculator.infer(['a',nil]).element_type
      expect(element_type.class).to eq(PStringType)
      inferred_type = calculator.infer_set(['a',nil])
      expect(inferred_type.class).to eq(PTupleType)
      element_types = inferred_type.types
      expect(element_types[0].class).to eq(PStringType)
      expect(element_types[1].class).to eq(PUndefType)
    end

    it 'infers on an empty Array produces Array[Unit,0,0]' do
      inferred_type = calculator.infer([])
      expect(inferred_type.element_type.class).to eq(PUnitType)
      expect(inferred_type.size_range).to eq([0, 0])
    end

    it 'infer_set on an empty Array produces Array[Unit,0,0]' do
      inferred_type = calculator.infer_set([])
      expect(inferred_type.element_type.class).to eq(PUnitType)
      expect(inferred_type.size_range).to eq([0, 0])
    end
  end

  context 'when determening callability' do
    context 'and given is exact' do
      it 'with callable' do
        required = callable_t(string_t)
        given = callable_t(string_t)
        expect(calculator.callable?(required, given)).to eq(true)
      end

      it 'with args tuple' do
        required = callable_t(string_t)
        given = tuple_t(string_t)
        expect(calculator.callable?(required, given)).to eq(true)
      end

      it 'with args tuple having a block' do
        required = callable_t(string_t, callable_t(string_t))
        given = tuple_t(string_t, callable_t(string_t))
        expect(calculator.callable?(required, given)).to eq(true)
      end

      it 'with args array' do
        required = callable_t(string_t)
        given = array_t(string_t, range_t(1, 1))
        expect(calculator.callable?(required, given)).to eq(true)
      end
    end

    context 'and given is more generic' do
      it 'with callable' do
        required = callable_t(string_t)
        given = callable_t(any_t)
        expect(calculator.callable?(required, given)).to eq(true)
      end

      it 'with args tuple' do
        required = callable_t(string_t)
        given = tuple_t(any_t)
        expect(calculator.callable?(required, given)).to eq(false)
      end

      it 'with args tuple having a block' do
        required = callable_t(string_t, callable_t(string_t))
        given = tuple_t(string_t, callable_t(any_t))
        expect(calculator.callable?(required, given)).to eq(true)
      end

      it 'with args tuple having a block with captures rest' do
        required = callable_t(string_t, callable_t(string_t))
        given = tuple_t(string_t, callable_t(any_t, 0, :default))
        expect(calculator.callable?(required, given)).to eq(true)
      end
    end

    context 'and given is more specific' do
      it 'with callable' do
        required = callable_t(any_t)
        given = callable_t(string_t)
        expect(calculator.callable?(required, given)).to eq(false)
      end

      it 'with args tuple' do
        required = callable_t(any_t)
        given = tuple_t(string_t)
        expect(calculator.callable?(required, given)).to eq(true)
      end

      it 'with args tuple having a block' do
        required = callable_t(string_t, callable_t(any_t))
        given = tuple_t(string_t, callable_t(string_t))
        expect(calculator.callable?(required, given)).to eq(false)
      end

      it 'with args tuple having a block with captures rest' do
        required = callable_t(string_t, callable_t(any_t))
        given = tuple_t(string_t, callable_t(string_t, 0, :default))
        expect(calculator.callable?(required, given)).to eq(false)
      end
    end
  end

  matcher :be_assignable_to do |type|
    match do |actual|
      type.is_a?(PAnyType) && type.assignable?(actual)
    end

    failure_message do |actual|
      "#{TypeFormatter.string(actual)} should be assignable to #{TypeFormatter.string(type)}"
    end

    failure_message_when_negated do |actual|
      "#{TypeFormatter.string(actual)} is assignable to #{TypeFormatter.string(type)} when it should not"
    end
  end
end
end
end
