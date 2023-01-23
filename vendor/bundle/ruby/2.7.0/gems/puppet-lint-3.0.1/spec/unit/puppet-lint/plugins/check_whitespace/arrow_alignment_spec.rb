require 'spec_helper'

describe 'arrow_alignment' do
  let(:msg) { 'indentation of => is not properly aligned (expected in column %d, but found it in column %d)' }

  context 'with fix disabled' do
    context 'selectors inside a resource' do
      let(:code) do
        <<-END
          file { 'foo':
            ensure  => $ensure,
            require => $ensure ? {
              present => Class['tomcat::install'],
              absent  => undef;
            },
            foo     => bar,
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'selectors in the middle of a resource' do
      let(:code) do
        <<-END
          file { 'foo':
            ensure => $ensure ? {
              present => directory,
              absent  => undef,
            },
            owner  => 'tomcat6',
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'selector inside a resource' do
      let(:code) do
        <<-END
          ensure => $ensure ? {
            present => directory,
            absent  => undef,
          },
          owner  => 'foo4',
          group  => 'foo4',
          mode   => '0755',
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'selector inside a hash inside a resource' do
      let(:code) do
        <<-END
          server => {
            ensure => ensure => $ensure ? {
              present => directory,
              absent  => undef,
            },
            ip     => '192.168.1.1'
          },
          owner  => 'foo4',
          group  => 'foo4',
          mode   => '0755',
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'nested hashes with correct indentation' do
      let(:code) do
        <<-END
          class { 'lvs::base':
            virtualeservers => {
              '192.168.2.13' => {
                vport        => '11025',
                service      => 'smtp',
                scheduler    => 'wlc',
                protocol     => 'tcp',
                checktype    => 'external',
                checkcommand => '/path/to/checkscript',
                real_servers => {
                  'server01' => {
                    real_server => '192.168.2.14',
                    real_port   => '25',
                    forwarding  => 'masq',
                  },
                  'server02' => {
                    real_server => '192.168.2.15',
                    real_port   => '25',
                    forwarding  => 'masq',
                  }
                }
              }
            }
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'single resource with a misaligned =>' do
      let(:code) do
        <<-END
          file { '/tmp/foo':
            foo => 1,
            bar => 2,
            gronk => 3,
            baz  => 4,
            meh => 5,
          }
        END
      end

      it 'detects four problems' do
        expect(problems).to have(4).problems
      end

      it 'creates four warnings' do
        expect(problems).to contain_warning(msg % [19, 17]).on_line(2).in_column(17)
        expect(problems).to contain_warning(msg % [19, 17]).on_line(3).in_column(17)
        expect(problems).to contain_warning(msg % [19, 18]).on_line(5).in_column(18)
        expect(problems).to contain_warning(msg % [19, 17]).on_line(6).in_column(17)
      end
    end

    context 'single resource with a misaligned => and semicolon at the end' do
      let(:code) do
        <<-END
          file { '/tmp/bar':
            foo => 1,
            bar => 2,
            gronk => 3,
            baz  => 4,
            meh => 5;
          }
        END
      end

      it 'detects four problems' do
        expect(problems).to have(4).problems
      end

      it 'creates four warnings' do
        expect(problems).to contain_warning(msg % [19, 17]).on_line(2).in_column(17)
        expect(problems).to contain_warning(msg % [19, 17]).on_line(3).in_column(17)
        expect(problems).to contain_warning(msg % [19, 18]).on_line(5).in_column(18)
        expect(problems).to contain_warning(msg % [19, 17]).on_line(6).in_column(17)
      end
    end

    context 'complex resource with a misaligned =>' do
      let(:code) do
        <<-END
          file { '/tmp/foo':
            foo => 1,
            bar  => $baz ? {
              gronk => 2,
              meh => 3,
            },
            meep => 4,
            bah => 5,
          }
        END
      end

      it 'detects three problems' do
        expect(problems).to have(3).problems
      end

      it 'creates three warnings' do
        expect(problems).to contain_warning(msg % [18, 17]).on_line(2).in_column(17)
        expect(problems).to contain_warning(msg % [21, 19]).on_line(5).in_column(19)
        expect(problems).to contain_warning(msg % [18, 17]).on_line(8).in_column(17)
      end
    end

    context 'multi-resource with a misaligned =>' do
      let(:code) do
        <<-END
          file {
            '/tmp/foo': ;
            '/tmp/bar':
              foo => 'bar';
            '/tmp/baz':
              gronk => 'bah',
              meh => 'no'
          }
        END
      end

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_warning(msg % [21, 19]).on_line(7).in_column(19)
      end
    end

    context 'multi-resource with a misaligned => and semicolons' do
      let(:code) do
        <<-END
          file {
            '/tmp/foo':
              ensure => 'directory',
              owner => 'root',
              mode => '0755';
            '/tmp/bar':
              ensure => 'directory';
            '/tmp/baz':
              ensure => 'directory',
              owner => 'root',
              mode => '0755';
          }
        END
      end

      it 'only detects a single problem' do
        expect(problems).to have(4).problem
      end

      it 'creates a warning' do
        expect(problems).to contain_warning(msg % [22, 21]).on_line(4).in_column(21)
        expect(problems).to contain_warning(msg % [22, 20]).on_line(5).in_column(20)
        expect(problems).to contain_warning(msg % [22, 21]).on_line(10).in_column(21)
        expect(problems).to contain_warning(msg % [22, 20]).on_line(11).in_column(20)
      end
    end

    context 'multiple single line resources' do
      let(:code) do
        <<-END
          file { 'foo': ensure => file }
          package { 'bar': ensure => present }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'resource with unaligned => in commented line' do
      let(:code) do
        <<-END
          file { 'foo':
            ensure => directory,
            # purge => true,
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'single line resource spread out on multiple lines' do
      let(:code) do
        <<-END
          file {
            'foo': ensure => present,
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'multiline resource with a single line of params' do
      let(:code) do
        <<-END
          mymodule::do_thing { 'some thing':
            whatever => { foo => 'bar', one => 'two' },
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'resource with aligned => too far out' do
      let(:code) do
        <<-END
          file { '/tmp/foo':
            ensure  => file,
            mode    => '0444',
          }
        END
      end

      it 'detects 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'creates 2 warnings' do
        expect(problems).to contain_warning(msg % [20, 21]).on_line(2).in_column(21)
        expect(problems).to contain_warning(msg % [20, 21]).on_line(3).in_column(21)
      end
    end

    context 'resource with multiple params where one is an empty hash' do
      let(:code) do
        <<-END
          foo { 'foo':
            a => true,
            b => {
            }
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'multiline resource with multiple params on a line' do
      let(:code) do
        <<-END
          user { 'test':
            a => 'foo', bb => 'bar',
            ccc => 'baz',
          }
        END
      end

      it 'detects 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'creates 2 warnings' do
        expect(problems).to contain_warning(msg % [17, 15]).on_line(2).in_column(15)
        expect(problems).to contain_warning(msg % [17, 28]).on_line(2).in_column(28)
      end
    end

    context 'resource param containing a single-element same-line hash' do
      let(:code) do
        <<-END
          foo { 'foo':
            a => true,
            b => { 'a' => 'b' }
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'multiline hash with opening brace on same line as first pair' do
      let(:code) do
        <<-END
          foo { 'foo':
            bar => [
              { aa => bb,
                c  => d},
            ],
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'unaligned multiline hash with opening brace on the same line as the first pair' do
      let(:code) do
        <<-END
          foo { 'foo':
            bar => [
              { aa => bb,
                c => d},
            ],
          }
        END
      end

      it 'detects one problem' do
        expect(problems).to have(1).problem
      end

      it 'creates one warning' do
        expect(problems).to contain_warning(msg % [20, 19]).on_line(4).in_column(19)
      end
    end

    context 'hash with strings containing variables as keys properly aligned' do
      let(:code) do
        <<-END
          foo { foo:
            param => {
              a         => 1
              "${aoeu}" => 2,
              b         => 3,
            },
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'hash with strings containing variables as keys incorrectly aligned' do
      let(:code) do
        <<-END
          foo { foo:
            param => {
              a => 1
              "${aoeu}" => 2,
              b     => 3,
            },
          }
        END
      end

      it 'detects 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'creates 2 warnings' do
        expect(problems).to contain_warning(msg % [25, 17]).on_line(3).in_column(17)
        expect(problems).to contain_warning(msg % [25, 21]).on_line(5).in_column(21)
      end
    end

    context 'complex data structure with different indentation levels at the same depth' do
      let(:code) do
        <<-END
          class { 'some_class':
            config_hash => {
              'a_hash'   => {
                'foo' => 'bar',
              },
              'an_array' => [
                {
                  foo => 'bar',
                  bar => 'baz',
                },
              ],
            },
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'where the top level of the block has no parameters' do
      let(:code) do
        <<-END
          case $::osfamily {
            'RedHat': {
              $datadir = $::operatingsystem ? {
                'Amazon' => pick($datadir, 'value'),
                default  => pick($datadir, 'value'),
              }
            }
          }
        END
      end

      it 'does not detect any problems' do
        expect(problems).to have(0).problems
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

    context 'single resource with a misaligned =>' do
      let(:code) do
        <<-END
          file { '/tmp/foo':
            foo => 1,
            bar => 2,
            gronk => 3,
            baz  => 4,
            meh => 5,
          }
        END
      end

      let(:fixed) do
        <<-END
          file { '/tmp/foo':
            foo   => 1,
            bar   => 2,
            gronk => 3,
            baz   => 4,
            meh   => 5,
          }
        END
      end

      it 'detects four problems' do
        expect(problems).to have(4).problems
      end

      it 'fixes the manifest' do
        expect(problems).to contain_fixed(msg % [19, 17]).on_line(2).in_column(17)
        expect(problems).to contain_fixed(msg % [19, 17]).on_line(3).in_column(17)
        expect(problems).to contain_fixed(msg % [19, 18]).on_line(5).in_column(18)
        expect(problems).to contain_fixed(msg % [19, 17]).on_line(6).in_column(17)
      end

      it 'aligns the arrows' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'complex resource with a misaligned =>' do
      let(:code) do
        <<-END
          file { '/tmp/foo':
            foo => 1,
            bar  => $baz ? {
              gronk => 2,
              meh => 3,
            },
            meep => 4,
            bah => 5,
          }
        END
      end

      let(:fixed) do
        <<-END
          file { '/tmp/foo':
            foo  => 1,
            bar  => $baz ? {
              gronk => 2,
              meh   => 3,
            },
            meep => 4,
            bah  => 5,
          }
        END
      end

      it 'detects three problems' do
        expect(problems).to have(3).problems
      end

      it 'fixes the manifest' do
        expect(problems).to contain_fixed(msg % [18, 17]).on_line(2).in_column(17)
        expect(problems).to contain_fixed(msg % [21, 19]).on_line(5).in_column(19)
        expect(problems).to contain_fixed(msg % [18, 17]).on_line(8).in_column(17)
      end

      it 'aligns the arrows' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'multi-resource with a misaligned =>' do
      let(:code) do
        <<-END
          file {
            '/tmp/foo': ;
            '/tmp/bar':
              foo => 'bar';
            '/tmp/baz':
              gronk => 'bah',
              meh => 'no'
          }
        END
      end

      let(:fixed) do
        <<-END
          file {
            '/tmp/foo': ;
            '/tmp/bar':
              foo => 'bar';
            '/tmp/baz':
              gronk => 'bah',
              meh   => 'no'
          }
        END
      end

      it 'only detects a single problem' do
        expect(problems).to have(1).problem
      end

      it 'fixes the manifest' do
        expect(problems).to contain_fixed(msg % [21, 19]).on_line(7).in_column(19)
      end

      it 'aligns the arrows' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'resource with aligned => too far out' do
      let(:code) do
        <<-END
          file { '/tmp/foo':
            ensure  => file,
            mode    => '0444',
          }
        END
      end

      let(:fixed) do
        <<-END
          file { '/tmp/foo':
            ensure => file,
            mode   => '0444',
          }
        END
      end

      it 'detects 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'creates 2 warnings' do
        expect(problems).to contain_fixed(msg % [20, 21]).on_line(2).in_column(21)
        expect(problems).to contain_fixed(msg % [20, 21]).on_line(3).in_column(21)
      end

      it 'realigns the arrows with the minimum whitespace' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'resource with unaligned => and no whitespace between param and =>' do
      let(:code) do
        <<-END
          user { 'test':
            param1 => 'foo',
            param2=> 'bar',
          }
        END
      end

      let(:fixed) do
        <<-END
          user { 'test':
            param1 => 'foo',
            param2 => 'bar',
          }
        END
      end

      it 'detects 1 problem' do
        expect(problems).to have(1).problem
      end

      it 'fixes the problem' do
        expect(problems).to contain_fixed(msg % [20, 19]).on_line(3).in_column(19)
      end

      it 'adds whitespace between the param and the arrow' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'multiline resource with multiple params on a line' do
      let(:code) do
        <<-END
          user { 'test':
            a => 'foo', bb => 'bar',
            ccc => 'baz',
          }
        END
      end

      let(:fixed) do
        <<-END
          user { 'test':
            a   => 'foo',
            bb  => 'bar',
            ccc => 'baz',
          }
        END
      end

      it 'detects 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'fixes 2 problems' do
        expect(problems).to contain_fixed(msg % [17, 15]).on_line(2).in_column(15)
        expect(problems).to contain_fixed(msg % [17, 28]).on_line(2).in_column(28)
      end

      it 'moves the extra param onto its own line and realign' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'multiline resource with multiple params on a line, extra one longer' do
      let(:code) do
        <<-END
          user { 'test':
            a => 'foo', bbccc => 'bar',
            ccc => 'baz',
          }
        END
      end

      let(:fixed) do
        <<-END
          user { 'test':
            a     => 'foo',
            bbccc => 'bar',
            ccc   => 'baz',
          }
        END
      end

      it 'detects 2 problems' do
        expect(problems).to have(3).problems
      end

      it 'fixes 2 problems' do
        expect(problems).to contain_fixed(msg % [19, 15]).on_line(2).in_column(15)
        expect(problems).to contain_fixed(msg % [19, 31]).on_line(2).in_column(31)
        expect(problems).to contain_fixed(msg % [19, 17]).on_line(3).in_column(17)
      end

      it 'moves the extra param onto its own line and realign' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'hash with strings containing variables as keys incorrectly aligned' do
      let(:code) do
        <<-END
          foo { foo:
            param => {
              a => 1
              "${aoeu}" => 2,
              b     => 3,
            },
          }
        END
      end

      let(:fixed) do
        <<-END
          foo { foo:
            param => {
              a         => 1
              "${aoeu}" => 2,
              b         => 3,
            },
          }
        END
      end

      it 'detects 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'fixes 2 problems' do
        expect(problems).to contain_fixed(msg % [25, 17]).on_line(3).in_column(17)
        expect(problems).to contain_fixed(msg % [25, 21]).on_line(5).in_column(21)
      end

      it 'aligns the hash rockets' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'complex data structure with different indentation levels at the same depth' do
      let(:code) do
        <<-END
          class { 'some_class':
            config_hash => {
              'a_hash'   => {
                'foo' => 'bar',
              },
              'an_array' => [
                {
                  foo => 'bar',
                  bar  => 'baz',
                },
              ],
            },
          }
        END
      end

      let(:fixed) do
        <<-END
          class { 'some_class':
            config_hash => {
              'a_hash'   => {
                'foo' => 'bar',
              },
              'an_array' => [
                {
                  foo => 'bar',
                  bar => 'baz',
                },
              ],
            },
          }
        END
      end

      it 'detects 1 problem' do
        expect(problems).to have(1).problems
      end

      it 'fixes 1 problem' do
        expect(problems).to contain_fixed(msg % [23, 24]).on_line(9).in_column(24)
      end

      it 'aligns the hash rockets' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'complex data structure with multiple token keys' do
      let(:code) do
        <<-END.gsub(%r{^ {10}}, '')
          class example (
            $external_ip_base,
          ) {

            bar { 'xxxxxxxxx':
              inputs => {
                'ny' => {
                  "${external_ip_base}.16:443 ${a} ${b} ${c}" => 'foo',
                  'veryveryverylongstring8:443'=> 'foo',
                  'simple'=> 'foo',
                  '3'=> :foo,
                  :baz=> :qux,
                  3=> 3,
                },
              },
            }
          }
        END
      end

      let(:fixed) do
        <<-END.gsub(%r{^ {10}}, '')
          class example (
            $external_ip_base,
          ) {

            bar { 'xxxxxxxxx':
              inputs => {
                'ny' => {
                  "${external_ip_base}.16:443 ${a} ${b} ${c}" => 'foo',
                  'veryveryverylongstring8:443'               => 'foo',
                  'simple'                                    => 'foo',
                  '3'                                         => :foo,
                  :baz                                        => :qux,
                  3                                           => 3,
                },
              },
            }
          }
        END
      end

      it 'detects 5 problems' do
        expect(problems).to have(5).problems
      end

      it 'fixes 5 problems' do
        expect(problems).to contain_fixed(msg % [53, 38]).on_line(9).in_column(38)
        expect(problems).to contain_fixed(msg % [53, 17]).on_line(10).in_column(17)
        expect(problems).to contain_fixed(msg % [53, 12]).on_line(11).in_column(12)
        expect(problems).to contain_fixed(msg % [53, 13]).on_line(12).in_column(13)
        expect(problems).to contain_fixed(msg % [53, 10]).on_line(13).in_column(10)
      end

      it 'realigns the arrows' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'realignment of resource with an inline single line hash' do
      let(:code) do
        <<-END.gsub(%r{^ {10}}, '')
          class { 'puppetdb':
            database                => 'embedded',
            #database                => 'postgres',
            #postgres_version        => '9.3',
            java_args               => { '-Xmx' => '512m', '-Xms' => '256m' },
            listen_address          => $::ipaddress_eth0,
            listen_port             => 4998,
            ssl_listen_address      => $::ipaddress_eth0,
            ssl_listen_port         => 4999,
            open_listen_port        => false,
            open_ssl_listen_port    => false;
          }
        END
      end

      let(:fixed) do
        <<-END.gsub(%r{^ {10}}, '')
          class { 'puppetdb':
            database             => 'embedded',
            #database                => 'postgres',
            #postgres_version        => '9.3',
            java_args            => { '-Xmx' => '512m', '-Xms' => '256m' },
            listen_address       => $::ipaddress_eth0,
            listen_port          => 4998,
            ssl_listen_address   => $::ipaddress_eth0,
            ssl_listen_port      => 4999,
            open_listen_port     => false,
            open_ssl_listen_port => false;
          }
        END
      end

      it 'detects 8 problems' do
        expect(problems).to have(8).problems
      end

      it 'fixes 8 problems' do
        expect(problems).to contain_fixed(msg % [24, 27]).on_line(2).in_column(27)
        expect(problems).to contain_fixed(msg % [24, 27]).on_line(5).in_column(27)
        expect(problems).to contain_fixed(msg % [24, 27]).on_line(6).in_column(27)
        expect(problems).to contain_fixed(msg % [24, 27]).on_line(7).in_column(27)
        expect(problems).to contain_fixed(msg % [24, 27]).on_line(8).in_column(27)
        expect(problems).to contain_fixed(msg % [24, 27]).on_line(9).in_column(27)
        expect(problems).to contain_fixed(msg % [24, 27]).on_line(10).in_column(27)
        expect(problems).to contain_fixed(msg % [24, 27]).on_line(11).in_column(27)
      end

      it 'realigns the arrows' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'negative argument' do
      let(:code) do
        <<-END
          res { 'a':
            x => { 'a' => '',
              'ab' => '',
            }
          }
        END
      end

      # TODO: This is not the desired behaviour, but adjusting the check to
      # properly format the hashes will need to wait until a major version
      # bump.
      let(:fixed) do
        <<-END
          res { 'a':
            x => { 'a' => '',
              'ab'     => '',
            }
          }
        END
      end

      it 'detects a problem' do
        expect(problems).to have(1).problem
      end

      it 'fixes the problems' do
        expect(problems).to contain_fixed(msg % [24, 20]).on_line(3).in_column(20)
      end

      it 'realigns the arrows' do
        expect(manifest).to eq(fixed)
      end
    end
  end
end
