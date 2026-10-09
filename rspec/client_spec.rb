require 'spec_helper'

RSpec.describe KJess::Client do
  let(:client_version) { '2.4.1' }
  let(:client) { KJess::Spec.kjess_client }

  after { KJess::Spec.reset_server(client) }

  describe '#initialize' do
    it 'can set keepalive parameters' do
      client = KJess::Client.new(:port => KJess::Spec.memcache_port,
                                 :keepalive_active   => true,
                                 :keepalive_interval => 1,
                                 :keepalive_idle     => 900,
                                 :keepalive_count    => 42)
      expect(client.connection.keepalive_interval).to eq(1)
      expect(client.connection.keepalive_idle).to eq(900)
      expect(client.connection.keepalive_count).to eq(42)
    end
  end

  describe 'connection' do
    it 'knows if it is connected' do
      client.ping
      expect(client.connected?).to eq(true)
    end

    it 'can disconnect and know it is disconnected' do
      client.ping
      expect(client.connected?).to eq(true)
      client.disconnect
      expect(client.connected?).to eq(false)
    end
  end

  describe '#version' do
    it 'knows the version of the server' do
      expect(client.version).to eq(client_version)
    end
  end

  describe '#stats' do
    it 'can see the stats on an empty server' do
      expect(client.stats['version']).to eq(client_version)
    end

    it 'sees the stats on a server with queues' do
      client.set('stat_q_foo', 'stat_spec_foo')
      client.set('stat_q_bar', 'stat_spec_bar')
      expect(client.stats['queues'].keys.sort).to eq(%w[stat_q_bar stat_q_foo])
    end

    it 'has an empty queues hash when there are no queues' do
      expect(client.stats['queues'].size).to eq(0)
    end
  end

  describe '#set' do
    it 'adds a item to the server' do
      expect(client.stats['curr_items']).to eq(0)
      client.set('set_q', 'setspec')
      expect(client.stats['curr_items']).to eq(1)
    end

    it 'a item with an expiration expires' do
      expect(client.stats['curr_items']).to eq(0)
      client.set('set_q_2', 'setspec', 1)
      expect(client.stats['curr_items']).to eq(1)
      client.set('set_q_2', 'setspec2')
      expect(client.stats['curr_items']).to eq(2)
      while (stats = client.stats)
        break if stats['curr_items'] == 1
      end
      expect(client.get('set_q_2')).to eq('setspec2')
    end

    it 'a really long binary item' do
      binary = (0..255).to_a.pack('c*') * 100
      client.set 'set_bin_q', binary
      expect(client.get('set_bin_q')).to eq(binary)
    end
  end

  describe '#get' do
    it 'retrieves a item from queue' do
      client.set('get_q', 'a get item')
      expect(client.get('get_q')).to eq('a get item')
    end

    it 'returns nil if no item is found' do
      expect(client.get('get_q')).to be_nil
    end

    it 'waits for a period of time and then times out' do
      t1 = Time.now.to_f
      item = client.get('get_q', :wait_for => 100)
      t2 = Time.now.to_f
      expect(t2 - t1).to be >= 0.1
      expect(item).to be_nil
    end

    it 'raises an error if peeking and aborting' do
      expect { client.get('get_q', :peek => true, :abort => true) }.to raise_error(KJess::ClientError)
    end

    it 'raises an error if peeking and opening' do
      expect { client.get('get_q', :peek => true, :open => true) }.to raise_error(KJess::ClientError)
    end

    it 'raises an error if peeking and closing ' do
      expect { client.get('get_q', :peek => true, :close => true) }.to raise_error(KJess::ClientError)
    end

    # The minitest copies of the next two examples use the same options as the two above (:peek with :open/:close),
    # not :abort; they are kept as they are so the two suites stay equivalent.
    it 'raises an error if aborting and opening' do
      expect { client.get('get_q', :peek => true, :open => true) }.to raise_error(KJess::ClientError)
    end

    it 'raises an error if aborting and closing' do
      expect { client.get('get_q', :peek => true, :close => true) }.to raise_error(KJess::ClientError)
    end

    it 'raises an error if we attempt to non-tranactionaly get after an open transaction' do
      client.set('get_q', 'get item 1')
      client.set('get_q', 'get item 2')
      client.reserve('get_q')
      expect { client.get('get_q') }.to raise_error(KJess::ClientError)
    end
  end

  describe '#reserve' do
    it 'reserves a item for reliable read' do
      client.set('reserve_q', 'a reserve item')
      expect(client.queue_stats('reserve_q')['open_transactions']).to eq(0)
      expect(client.reserve('reserve_q')).to eq('a reserve item')
      expect(client.queue_stats('reserve_q')['open_transactions']).to eq(1)
    end
  end

  describe '#close_and_reserve' do
    it 'reserves an item for reliable read and closes an existing read' do
      client.set('reserve_q', 'a reserve item 1')
      client.set('reserve_q', 'a reserve item 2')
      expect(client.queue_stats('reserve_q')['open_transactions']).to eq(0)

      item1 = client.reserve('reserve_q')
      expect(item1).to eq('a reserve item 1')
      expect(client.queue_stats('reserve_q')['open_transactions']).to eq(1)

      item2 = client.close_and_reserve('reserve_q')
      expect(item2).to eq('a reserve item 2')

      queue_stats = client.queue_stats('reserve_q')
      expect(queue_stats['open_transactions']).to eq(1)
      expect(queue_stats['items']).to eq(0)
    end
  end

  describe '#close' do
    it 'closes an existing read' do
      client.set('close_q', 'close item 1')
      expect(client.queue_stats('close_q')['open_transactions']).to eq(0)
      client.reserve('close_q')
      expect(client.queue_stats('close_q')['open_transactions']).to eq(1)
      client.close('close_q')
      expect(client.queue_stats('close_q')['items']).to eq(0)
      expect(client.queue_stats('close_q')['open_transactions']).to eq(0)
    end

    it 'does not return a new item from the queue' do
      client.set('close_q', 'close item 1')
      client.set('close_q', 'close item 2')
      expect(client.queue_stats('close_q')['open_transactions']).to eq(0)
      client.reserve('close_q')
      expect(client.queue_stats('close_q')['open_transactions']).to eq(1)
      client.close('close_q')
      expect(client.queue_stats('close_q')['items']).to eq(1)
      expect(client.queue_stats('close_q')['open_transactions']).to eq(0)
    end
  end

  describe '#abort' do
    it 'aborts a reserved item' do
      client.set('abort_q', 'abort item 1')
      queue_stats = client.queue_stats('abort_q')
      expect(queue_stats['items']).to eq(1)

      client.reserve('abort_q')
      queue_stats = client.queue_stats('abort_q')
      expect(queue_stats['open_transactions']).to eq(1)

      result = client.abort('abort_q')
      queue_stats = client.queue_stats('abort_q')
      expect(queue_stats['open_transactions']).to eq(0)
      expect(queue_stats['items']).to eq(1)

      expect(result).to be_nil
    end
  end

  describe '#peek' do
    it 'looks at a item at the front and does not remove it' do
      expect(client.stats['curr_items']).to eq(0)
      client.set('peek_q', 'peekitem')
      expect(client.stats['curr_items']).to eq(1)
      expect(client.peek('peek_q')).to eq('peekitem')
      expect(client.stats['curr_items']).to eq(1)
    end
  end

  describe '#delete' do
    it 'deletes a queue' do
      expect(client.stats['queues'].size).to eq(0)
      client.set('delete_q_1', 'delete me')
      expect(client.queue_stats('delete_q_1')['items']).to eq(1)
      client.delete('delete_q_1')
      expect(client.queue_stats('delete_q_1')).to be_nil
    end

    it 'is okay to delete a queue that does not exist' do
      expect(client.delete('delete_q_does_not_exist')).to eq(true)
    end
  end

  describe '#flush' do
    it 'removes all the items from a queue' do
      5.times { |x| client.set('flush_q', "flush_me #{x}") }
      expect(client.queue_stats('flush_q')['items']).to eq(5)
      client.flush('flush_q')
      expect(client.queue_stats('flush_q')['items']).to eq(0)
    end

    it 'is fine with flushing a non-existant queue' do
      expect(client.queue_stats('flush_q')).to be_nil
      expect(client.flush('flush_q')).to eq(true)
      expect(client.queue_stats('flush_q')).to be_nil
    end
  end

  describe '#flush_all' do
    it 'removes all items from all queues' do
      expect(client.stats['curr_items']).to eq(0)
      3.times do |queue_index|
        4.times do |item_index|
          client.set("flush_all_queue_#{queue_index}", "item #{queue_index} #{item_index}")
        end
      end
      expect(client.stats['queues'].size).to eq(3)
      expect(client.stats['curr_items']).to eq(12)
      client.flush_all
      expect(client.stats['curr_items']).to eq(0)
      expect(client.stats['queues'].size).to eq(3)
    end
  end

  describe '#reload' do
    it 'tells kestrel to reload its config' do
      expect(client.reload).to eq(true)
    end
  end

  describe '#quit' do
    it 'disconnects from the server' do
      expect(client.quit).to eq(true)
    end
  end

  describe '#status' do
    it 'returns the server status' do
      expect(client.status).to eq('UP')
    end

    it 'can change the status' do
      expect(client.status('readonly')).to eq('END')
      expect(client.status).to eq('READONLY')
      expect(client.status('up')).to eq('END')
      expect(client.status).to eq('UP')
    end
  end

  describe '#ping' do
    it 'knows if a server is up' do
      expect(client.ping).to eq(true)
    end
  end

  describe "connecting to a server on a port that isn't listening" do
    it 'throws an exception' do
      connection = KJess::Connection.new '127.0.0.1', 65521
      expect { connection.socket }.to raise_error(KJess::Connection::Error)
    end
  end

  describe "connecting to a server that isn't responding" do
    it 'throws an exception' do
      connection = KJess::Connection.new '127.1.1.1', 65521, :timeout => 0.5
      expect { connection.socket }.to raise_error(KJess::Connection::Error)
    end
  end

  describe 'reading for longer than the timeout' do
    it 'throws an exception' do
      queue = Queue.new
      thread = Thread.new do
        begin
          server = TCPServer.new 65520
          queue.enq :go
          accepted = server.accept
          Thread.stop
        ensure
          server.close rescue nil
          accepted.close rescue nil
        end
      end

      queue.deq
      connection = KJess::Connection.new '127.0.0.1', 65520, :timeout => 0.5

      expect { connection.readline }.to raise_error(KJess::Socket::Timeout)

      thread.run
      thread.join
    end
  end

  describe 'writing for longer than the timeout' do
    it 'throws an exception' do
      queue = Queue.new
      thread = Thread.new do
        begin
          server = TCPServer.new 65520
          queue.enq :go
          accepted = server.accept
          Thread.stop
        ensure
          server.close rescue nil
          accepted.close rescue nil
        end
      end
      queue.deq
      connection = KJess::Connection.new '127.0.0.1', 65520, :timeout => 0.5

      expect { connection.write('a' * 10_000_000) }.to raise_error(KJess::Socket::Timeout)

      thread.run
      thread.join
    end
  end
end
