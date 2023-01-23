require 'spec_helper'

describe 'file_mode' do
  let(:msg) { 'mode should be represented as a 4 digit octal value or symbolic mode' }

  context 'with fix disabled' do
    context '3 digit file mode' do
      let(:code) { "file { 'foo': mode => '777' }" }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_warning(msg).on_line(1).in_column(23)
      end
    end

    context '4 digit file mode' do
      let(:code) { "file { 'foo': mode => '0777' }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'file mode as a variable' do
      let(:code) { "file { 'foo': mode => $file_mode }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'symbolic file mode' do
      let(:code) { "file { 'foo': mode => 'u=rw,og=r' }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'file mode undef unquoted' do
      let(:code) { "file { 'foo': mode => undef }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'file mode undef quoted' do
      let(:code) { "file { 'foo': mode => 'undef' }" }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_warning(msg).on_line(1).in_column(23)
      end
    end

    context 'mode as audit value' do
      let(:code) { "file { '/etc/passwd': audit => [ owner, mode ], }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context '3 digit concat mode' do
      let(:code) { "concat { 'foo': mode => '777' }" }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_warning(msg).on_line(1).in_column(25)
      end
    end

    context '4 digit concat mode' do
      let(:code) { "concat { 'foo': mode => '0777' }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'concat mode as a variable' do
      let(:code) { "concat { 'foo': mode => $concat_mode }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'symbolic concat mode' do
      let(:code) { "concat { 'foo': mode => 'u=rw,og=r' }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'concat mode undef unquoted' do
      let(:code) { "concat { 'foo': mode => undef }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'concat mode undef quoted' do
      let(:code) { "concat { 'foo': mode => 'undef' }" }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_warning(msg).on_line(1).in_column(25)
      end
    end

    context 'mode as audit value' do
      let(:code) { "concat { '/etc/passwd': audit => [ owner, mode ], }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'mode as a function return value' do
      let(:code) { "file { 'foo': mode => lookup('bar'), }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'multi body file bad modes selector' do
      let(:code) do
        <<-END
          file {
            '/tmp/foo1':
              ensure => $foo ? { default => absent },
              mode => 644;
            '/tmp/foo2':
              mode => 644;
            '/tmp/foo3':
              mode => 644;
          }
        END
      end

      it 'detects 3 problems' do
        expect(problems).to have(3).problems
      end

      it 'creates three warnings' do
        expect(problems).to contain_warning(sprintf(msg)).on_line(4).in_column(23)
        expect(problems).to contain_warning(sprintf(msg)).on_line(6).in_column(23)
        expect(problems).to contain_warning(sprintf(msg)).on_line(8).in_column(23)
      end
    end
  end

  context 'with fix enabled' do
    before(:each) do
      PuppetLint.configuration.fix = true
    end

    after(:each) do
      PuppetLint.configuration.fix = false
    end

    context '3 digit file mode' do
      let(:code) { "file { 'foo': mode => '777' }" }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'fixes the manifest' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(23)
      end

      it 'zeroe pads the file mode' do
        expect(manifest).to eq("file { 'foo': mode => '0777' }")
      end
    end

    context 'file mode undef quoted' do
      let(:code) { "file { 'foo': mode => 'undef' }" }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_warning(msg).on_line(1).in_column(23)
      end

      it 'does not modify the original manifest' do
        expect(manifest).to eq(code)
      end
    end

    context '3 digit concat mode' do
      let(:code) { "concat { 'foo': mode => '777' }" }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'fixes the manifest' do
        expect(problems).to contain_fixed(msg).on_line(1).in_column(25)
      end

      it 'zero pads the concat mode' do
        expect(manifest).to eq("concat { 'foo': mode => '0777' }")
      end
    end

    context 'concat mode undef quoted' do
      let(:code) { "concat { 'foo': mode => 'undef' }" }

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_warning(msg).on_line(1).in_column(25)
      end

      it 'does not modify the original manifest' do
        expect(manifest).to eq(code)
      end
    end

    context 'mode as a function return value' do
      let(:code) { "file { 'foo': mode => lookup('bar'), }" }

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end

      it 'does not change the manifest' do
        expect(manifest).to eq(code)
      end
    end

    context 'multi body file bad modes selector' do
      let(:code) do
        <<-END
          file {
            '/tmp/foo1':
              ensure => $foo ? { default => absent },
              mode => 644;
            '/tmp/foo2':
              mode => 644;
            '/tmp/foo3':
              mode => 644;
          }
        END
      end

      let(:fixed) do
        <<-END
          file {
            '/tmp/foo1':
              ensure => $foo ? { default => absent },
              mode => '0644';
            '/tmp/foo2':
              mode => '0644';
            '/tmp/foo3':
              mode => '0644';
          }
        END
      end

      it 'detects 3 problems' do
        expect(problems).to have(3).problems
      end

      it 'fixes 3 problems' do
        expect(problems).to contain_fixed(msg).on_line(4).in_column(23)
        expect(problems).to contain_fixed(msg).on_line(6).in_column(23)
        expect(problems).to contain_fixed(msg).on_line(8).in_column(23)
      end

      it 'zero pads the file modes and change them to strings' do
        expect(manifest).to eq(fixed)
      end
    end
  end
end
