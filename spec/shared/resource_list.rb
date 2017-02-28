require 'spec_helper'

shared_examples 'resource list' do
  describe '#options' do
    subject{ @list.options }

    it{ is_expected.to be_a(Hash) }
    it{ is_expected.to be_frozen }

    it 'stores options' do
      expect( subject ).to eq(limit: 1)
    end
  end

  describe '#meta' do
    subject{ @list.meta }

    it{ is_expected.to be_a(Hash) }
    it{ is_expected.to be_frozen }
  end

  describe '#total' do
    subject{ @list.total }

    it{ is_expected.to be_an(Integer) }

    it 'returns a "total" value from metadata' do
      expect( subject ).to eq @list.meta["total"]
    end
  end

  describe '#loaded' do
    subject{ @list.loaded }

    it{ is_expected.to be_an(Integer) }

    it 'contains currently loaded objects count' do
      size = rand(2..10)
      allow(@list).to receive(:objects){ Array.new(size) }

      expect( subject ).to eq(size)
    end
  end

  describe '#each' do
    it 'when called without a block, returns an Enumerator' do
      expect( subject.each ).to be_an(Enumerator)
    end

    it 'when called with a block, returns self' do
      allow(subject).to receive(:meta){ {"next" => nil} }
      expect( subject.each{|o| nil } ).to eq(subject)
    end

    it 'when called with a break inside a block, returns nil' do
      expect( subject.each{|o| break } ).to be_nil
    end
  end

  describe '#[]' do
    it "returns instances of a resource class" do
      expect( subject[0] ).to be_a(resource_class)
    end
  end

  describe 'enumerable interface' do
    subject{ @list.dup }

    it 'is an Enumerable' do
      expect( subject ).to be_an(Enumerable)
    end

    it 'iterates through objects' do
      i, uuids = 0, []
      subject.each{|object| uuids << object.uuid; i+=1; break if i >= 2 }

      expect(uuids.size).to eq 2
      expect(uuids).to eq([subject[0].uuid, subject[1].uuid])
    end

    it 'loads additional objects when needed' do
      expect(@api).to receive(:get)
        .with(subject.meta["next"]).and_call_original

      objects = subject.first(2)

      expect(objects.size).to eq(2)
    end

    it "loads different objects" do
      expect(@api).to receive(:get)
        .with(subject.meta["next"]).and_call_original

      objects = subject.first(2)

      expect(objects[0].uuid).not_to eq(objects[1].uuid)
    end

    it 'stops loading objects when no objects left' do
      allow(@api).to receive(:get).and_wrap_original do |m, *args|
        m.call(*args).tap{|data| data["next"] = nil}
      end

      uuids = subject.map{|object| object.uuid}

      expect( uuids.size ).to eq(2)
    end

    it 'preserves loaded objects' do
      expect( subject.loaded ).to eq(1)

      subject.first(2)

      expect( subject.loaded ).to eq(2)
    end

    it 'updates #meta with data from last api response' do
      new_meta = {}
      allow(@api).to receive(:get).and_wrap_original do |m, *args|
        m.call(*args).tap{|data| new_meta = data.reject{|k,_| k == "results"}}
      end

      subject.first(2)

      expect( subject.meta ).to eq(new_meta)
    end

    if Gem.ruby_version >= Gem::Version.new('2.0.0')
      context 'when lazy enumerator is used' do
        it 'preserves loaded objects' do
          expect(subject.loaded).to eq 1

          subject.lazy.first(2)

          expect(subject.loaded).to eq 2
        end
      end
    end

    context 'when a block passed to an enumerator method contains a break' do
      it 'preserves loaded objects' do
        i = 0
        subject.each{|o| i+= 1; break if i >= 2}

        expect( subject.loaded ).to eq(2)
      end
    end

    context 'when a block passed to an enumerator method raises an exception' do
      it 'preserves loaded objects' do
        i = 0
        subject.each{|o| i += 1; raise if i>= 2} rescue nil

        expect( subject.loaded ).to eq(2)
      end
    end
  end
end
