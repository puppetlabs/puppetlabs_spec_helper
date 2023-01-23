require 'spec_helper'
require 'semantic_puppet/dependency'

describe SemanticPuppet::Dependency do
  def create_release(source, name, version, deps = {})
    SemanticPuppet::Dependency::ModuleRelease.new(
      source,
      name,
      SemanticPuppet::Version.parse(version),
      Hash[deps.map { |k, v| [k, SemanticPuppet::VersionRange.parse(v) ] }]
    )
  end

  describe '.sources' do
    it 'defaults to an empty list' do
      expect(subject.sources).to be_empty
    end

    it 'is frozen' do
      expect(subject.sources).to be_frozen
    end

    it 'can be modified by using #add_source' do
      subject.add_source(SemanticPuppet::Dependency::Source.new)
      expect(subject.sources).to_not be_empty
    end

    it 'can be emptied by using #clear_sources' do
      subject.add_source(SemanticPuppet::Dependency::Source.new)
      subject.clear_sources
      expect(subject.sources).to be_empty
    end
  end

  describe '.query' do
    context 'without sources' do
      it 'returns an unsatisfied ModuleRelease' do
        expect(subject.query('module_name' => '1.0.0')).to_not be_satisfied
      end
    end

    context 'with one source' do
      let(:source) { double('Source', :priority => 0) }

      before do
        SemanticPuppet::Dependency.clear_sources
        SemanticPuppet::Dependency.add_source(source)
      end

      it 'queries the source for release information' do
        expect(source).to receive(:fetch).with('module_name').and_return([])

        SemanticPuppet::Dependency.query('module_name' => '1.0.0')
      end

      it 'queries the source for each dependency' do
        expect(source).to receive(:fetch).with('module_name').and_return([
          create_release(source, 'module_name', '1.0.0', 'bar' => '1.0.0')
        ])
        expect(source).to receive(:fetch).with('bar').and_return([])

        SemanticPuppet::Dependency.query('module_name' => '1.0.0')
      end

      it 'queries the source for each dependency only once' do
        expect(source).to receive(:fetch).with('module_name').and_return([
          create_release(
            source,
            'module_name',
            '1.0.0',
            'bar' => '1.0.0', 'baz' => '0.0.2'
          )
        ])
        expect(source).to receive(:fetch).with('bar').and_return([
          create_release(source, 'bar', '1.0.0', 'baz' => '0.0.3')
        ])
        expect(source).to receive(:fetch).with('baz').once.and_return([])

        SemanticPuppet::Dependency.query('module_name' => '1.0.0')
      end

      it 'returns a ModuleRelease with the requested dependencies' do
        allow(source).to receive(:fetch).and_return([])

        result = SemanticPuppet::Dependency.query('foo' => '1.0.0', 'bar' => '1.0.0')
        expect(result.dependency_names).to match_array %w[ foo bar ]
      end

      it 'populates the returned ModuleRelease with related dependencies' do
        allow(source).to receive(:fetch).and_return(
          [ foo = create_release(source, 'foo', '1.0.0', 'bar' => '1.0.0') ],
          [ bar = create_release(source, 'bar', '1.0.0') ]
        )

        result = SemanticPuppet::Dependency.query('foo' => '1.0.0', 'bar' => '1.0.0')
        expect(result.dependencies['foo']).to eql [foo]
        expect(result.dependencies['bar']).to eql [bar]
      end

      it 'populates all returned ModuleReleases with related dependencies' do
        allow(source).to receive(:fetch).and_return(
          [ foo = create_release(source, 'foo', '1.0.0', 'bar' => '1.0.0') ],
          [ bar = create_release(source, 'bar', '1.0.0', 'baz' => '0.1.0') ],
          [ baz = create_release(source, 'baz', '0.1.0', 'baz' => '1.0.0') ]
        )

        result = SemanticPuppet::Dependency.query('foo' => '1.0.0')
        expect(result.dependencies['foo']).to eql [foo]
        expect(foo.dependencies['bar']).to eql [bar]
        expect(bar.dependencies['baz']).to eql [baz]
      end
    end

    context 'with multiple sources' do
      let(:source1) { double('SourceOne', :priority => 0) }
      let(:source2) { double('SourceTwo', :priority => 0) }
      let(:source3) { double('SourceThree', :priority => 0) }

      before do
        SemanticPuppet::Dependency.add_source(source1)
        SemanticPuppet::Dependency.add_source(source2)
        SemanticPuppet::Dependency.add_source(source3)
      end

      it 'queries each source in turn' do
        expect(source1).to receive(:fetch).with('module_name').and_return([])
        expect(source2).to receive(:fetch).with('module_name').and_return([])
        expect(source3).to receive(:fetch).with('module_name').and_return([])

        SemanticPuppet::Dependency.query('module_name' => '1.0.0')
      end

      it 'resolves all dependencies against all sources' do
        expect(source1).to receive(:fetch).with('module_name').and_return([
          create_release(source1, 'module_name', '1.0.0', 'bar' => '1.0.0')
        ])
        expect(source2).to receive(:fetch).with('module_name').and_return([])
        expect(source3).to receive(:fetch).with('module_name').and_return([])

        expect(source1).to receive(:fetch).with('bar').and_return([])
        expect(source2).to receive(:fetch).with('bar').and_return([])
        expect(source3).to receive(:fetch).with('bar').and_return([])

        SemanticPuppet::Dependency.query('module_name' => '1.0.0')
      end
    end
  end

  describe '.resolve' do
    def add_source_modules(name, versions, deps = {})
      versions = Array(versions)
      releases = versions.map { |ver| create_release(source, name, ver, deps) }
      allow(source).to receive(:fetch).with(name).and_return(modules[name].concat(releases))
    end

    def subject(specs)
      graph = SemanticPuppet::Dependency.query(specs)
      yield graph if block_given?
      expect(graph.dependencies).to_not be_empty
      result = SemanticPuppet::Dependency.resolve(graph)
      expect(graph.dependencies).to_not be_empty
      result.map { |rel| [ rel.name, rel.version.to_s ] }
    end

    let(:modules) { Hash.new { |h,k| h[k] = [] }}
    let(:source) { double('Source', :priority => 0) }

    before { SemanticPuppet::Dependency.add_source(source) }

    context 'for a module without dependencies' do
      def foo(range)
        subject('foo' => range).map { |x| x.last }
      end

      it 'returns the greatest release matching the version range' do
        add_source_modules('foo', %w[ 0.9.0 1.0.0 1.1.0 2.0.0 ])

        expect(foo('1.x')).to eql %w[ 1.1.0 ]
      end

      context 'when the query includes both stable and prerelease versions' do
        it 'returns the greatest stable release matching the range' do
          add_source_modules('foo', %w[ 0.9.0 1.0.0 1.1.0 1.2.0-pre 2.0.0 ])

          expect(foo('1.x')).to eql %w[ 1.1.0 ]
        end
      end

      context 'when the query omits all stable versions' do
        it 'returns the greatest prerelease version matching the range' do
          add_source_modules('foo', %w[ 1.0.0 1.1.0-a 1.1.0-b 2.0.0 ])

          expect(foo('>1.1.0-a <2.0.0')).to eql %w[ 1.1.0-b ]
          expect(foo('1.1.0-a')).to eql %w[ 1.1.0-a ]
        end
      end

      context 'when the query omits all versions' do
        it 'fails with an appropriate message' do
          add_source_modules('foo', %w[ 1.0.0 1.1.0-a 1.1.0 ])

          with_message = /Could not find satisfying releases/
          expect { foo('2.x') }.to raise_exception with_message
          expect { foo('2.x') }.to raise_exception /\bfoo\b/
        end
      end
    end

    context 'for a module with dependencies' do
      def foo(range)
        subject('foo' => range)
      end

      it 'returns the greatest releases matching the dependency range' do
        add_source_modules('foo', '1.1.0', 'bar' => '1.x')
        add_source_modules('bar', %w[ 0.9.0 1.0.0 1.1.0 1.2.0 2.0.0 ])

        expect(foo('1.1.0')).to include %w[ foo 1.1.0 ], %w[ bar 1.2.0 ]
      end

      context 'when the dependency has both stable and prerelease versions' do
        it 'returns the greatest stable release matching the range' do
          add_source_modules('foo', '1.1.0', 'bar' => '1.x')
          add_source_modules('bar', %w[ 0.9.0 1.0.0 1.1.0 1.2.0-pre 2.0.0 ])

          expect(foo('1.1.0')).to include %w[ foo 1.1.0 ], %w[ bar 1.1.0 ]
        end
      end

      context 'when the dependency has no stable versions' do
        it 'returns the greatest prerelease version matching the range' do
          add_source_modules('foo', '1.1.0', 'bar' => '>=1.1.0-0 <1.2.0')
          add_source_modules('foo', '1.1.1', 'bar' => '1.1.0-a')
          add_source_modules('bar', %w[ 1.0.0 1.1.0-a 1.1.0-b 2.0.0 ])

          expect(foo('1.1.0')).to include %w[ foo 1.1.0 ], %w[ bar 1.1.0-b ]
          expect(foo('1.1.1')).to include %w[ foo 1.1.1 ], %w[ bar 1.1.0-a ]
        end
      end

      context 'when the dependency cannot be satisfied' do
        it 'fails with an appropriate message' do
          add_source_modules('foo', %w[ 1.1.0 ], 'bar' => '1.x')
          add_source_modules('bar', %w[ 0.0.1 0.1.0-a 0.1.0 ])

          with_message = /Could not find satisfying releases/
          expect { foo('1.1.0') }.to raise_exception with_message
          expect { foo('1.1.0') }.to raise_exception /\bfoo\b/
        end
      end
    end

    context 'for a module with competing dependencies' do
      def foo(range)
        subject('foo' => range)
      end

      context 'that overlap' do
        it 'returns the greatest release satisfying all dependencies' do
          add_source_modules('foo', '1.1.0', 'bar' => '1.0.0', 'baz' => '1.0.0')
          add_source_modules('bar', '1.0.0', 'quxx' => '1.x')
          add_source_modules('baz', '1.0.0', 'quxx' => '1.1.x')
          add_source_modules('quxx', %w[ 0.9.0 1.0.0 1.1.0 1.1.1 1.2.0 2.0.0 ])

          expect(foo('1.1.0')).to_not include %w[ quxx 1.2.0 ]
          expect(foo('1.1.0')).to include %w[ quxx 1.1.1 ]
        end
      end

      context 'that do not overlap' do
        it 'fails with an appropriate message' do
          add_source_modules('foo','1.1.0', 'bar' => '1.0.0', 'baz' => '1.0.0')
          add_source_modules('bar','1.0.0', 'quxx' => '1.x')
          add_source_modules('baz','1.0.0', 'quxx' => '2.x')
          add_source_modules('quxx', %w[ 0.9.0 1.0.0 1.1.0 1.1.1 1.2.0 2.0.0 ])

          with_message = /Could not find satisfying releases/
          expect { foo('1.1.0') }.to raise_exception with_message
          expect { foo('1.1.0') }.to raise_exception /\bfoo\b/
        end
      end
    end

    context 'for a module with circular dependencies' do
      def foo(range)
        subject('foo' => range)
      end

      context 'that can be resolved' do
        it 'terminates' do
          add_source_modules('foo', '1.1.0', 'foo' => '1.x')

          expect(foo('1.1.0')).to include %w[ foo 1.1.0 ]
        end
      end

      context 'that cannot be resolved' do
        it 'fails with an appropriate message' do
          add_source_modules('foo', '1.1.0', 'foo' => '1.0.0')

          with_message = /Could not find satisfying releases/
          expect { foo('1.1.0') }.to raise_exception with_message
          expect { foo('1.1.0') }.to raise_exception /\bfoo\b/
        end
      end
    end

    context 'for a module with dependencies' do
      context 'that violate module constraints on the graph' do
        def foo(range)
          subject('foo' => range) do |graph|
            graph.add_constraint('no downgrade', 'bar', '> 3.0.0') do |node|
              SemanticPuppet::VersionRange.parse('> 3.0.0') === node.version
            end
          end
        end

        context 'that can be resolved' do
          it 'terminates' do
            add_source_modules('foo', '1.1.0', 'bar' => '1.x')
            add_source_modules('foo', '1.2.0', 'bar' => '>= 2.0.0')
            add_source_modules('bar', '1.0.0')
            add_source_modules('bar', '2.0.0', 'baz' => '>= 1.0.0')
            add_source_modules('bar', '3.0.0')
            add_source_modules('bar', '3.0.1')
            add_source_modules('baz', '1.0.0')

            expect(foo('1.x')).to include %w[ foo 1.2.0 ], %w[ bar 3.0.1 ]
          end
        end

        context 'that cannot be resolved' do
          it 'fails with an appropriate message' do
            add_source_modules('foo', '1.1.0', 'bar' => '1.x')
            add_source_modules('foo', '1.2.0', 'bar' => '2.x')
            add_source_modules('bar', '1.0.0', 'baz' => '1.x')
            add_source_modules('bar', '2.0.0', 'baz' => '1.x')
            add_source_modules('baz', '1.0.0')
            add_source_modules('baz', '3.0.0')
            add_source_modules('baz', '3.0.1')

            with_message = /Could not find satisfying releases/
            expect { foo('1.x') }.to raise_exception with_message
            expect { foo('1.x') }.to raise_exception /\bfoo\b/
          end
        end
      end
    end

    context 'that violate graph constraints' do
      def foo(range)
        subject('foo' => range) do |graph|
          graph.add_graph_constraint('uniqueness') do |nodes|
            nodes.none? { |node| node.name =~ /z/ }
          end
        end
      end

      context 'that can be resolved' do
        it 'terminates' do
          add_source_modules('foo', '1.1.0', 'bar' => '1.x')
          add_source_modules('foo', '1.2.0', 'bar' => '2.x')
          add_source_modules('bar', '1.0.0')
          add_source_modules('bar', '2.0.0', 'baz' => '1.0.0')
          add_source_modules('baz', '1.0.0')

          expect(foo('1.x')).to include %w[ foo 1.1.0 ], %w[ bar 1.0.0 ]
        end
      end

      context 'that cannot be resolved' do
        it 'fails with an appropriate message' do
          add_source_modules('foo', '1.1.0', 'bar' => '1.x')
          add_source_modules('foo', '1.2.0', 'bar' => '2.x')
          add_source_modules('bar', '1.0.0', 'baz' => '1.0.0')
          add_source_modules('bar', '2.0.0', 'baz' => '1.0.0')
          add_source_modules('baz', '1.0.0')

          with_message = /Could not find satisfying releases/
          expect { foo('1.1.0') }.to raise_exception with_message
          expect { foo('1.1.0') }.to raise_exception /\bfoo\b/
        end
      end
    end
  end
end
