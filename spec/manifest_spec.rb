require_relative "spec_helper"

describe "Manifest" do
  let(:manifest) { Hotel::Manifest.new }
  describe "Manifest#initialize" do
    it "is an instance of Manifest" do
      expect(manifest).must_be_instance_of Hotel::Manifest
    end

    let(:rooms) { manifest.rooms }
    describe "Check attributes of Manifest" do
      it "instance variable rooms is an array" do
        expect(rooms).must_be_instance_of Array
      end

      it "each element is a type of room" do
        rooms.each do |room|
          expect(room).must_be_instance_of Hotel::Room
        end
      end
    end
  end

  describe "Manifest#setup_rooms" do
    it "will setup rooms (called in constructor)" do
      new_manifest = Hotel::Manifest.new(rooms_to_set_up: [{ cost_per_night: 1.11, number_of_rooms: 7 }])
      expect(new_manifest.rooms.length).must_equal 7
      new_manifest.rooms.each do |room|
        expect(room.cost_per_night).must_equal 1.11
      end
    end
    it "will setup rooms with of multiple groupings" do
      multi_manifest = Hotel::Manifest.new(rooms_to_set_up: [{ cost_per_night: 200, number_of_rooms: 3 },
                                                             { cost_per_night: 230, number_of_rooms: 5 }])
      number_rooms_created = multi_manifest.rooms.length
      expect(number_rooms_created).must_equal 8
      cost_array = [200, 200, 200, 230, 230, 230, 230, 230, 230]
      number_rooms_created.times do |i|
        expect(multi_manifest.rooms[i].cost_per_night == cost_array[i]).must_equal true
      end
    end
  end
  describe "Manifest#add_room_to_rooms" do
    it "will add new room to rooms" do
      old_last_room = manifest.rooms[-1]
      manifest.add_room_to_rooms(cost_per_night: 333.33)
      new_last_room = manifest.rooms[-1]
      expect(new_last_room.cost_per_night).must_equal 333.33
      expect(old_last_room != new_last_room).must_equal true
    end
  end

  describe "Manifest#find_room" do
    it "will return room" do
      expect(manifest.find_room(id: 3)).must_be_instance_of Hotel::Room
    end

    it "return correct room if room is in rooms" do
      expect(manifest.find_room(id: 3)).must_equal manifest.rooms[2]
    end

    it "returns nil if room is not in rooms" do
      expect(manifest.find_room(id: manifest.rooms.length + 3)).must_be_nil
    end
  end

  describe "Manifest#list_rooms" do
    it "returns an array" do
      expect(manifest.list_rooms).must_be_instance_of Array
    end

    it "returns [] if rooms to list is empty array" do
      expect(manifest.list_rooms(rooms_to_list: [])).must_equal []
    end

    it "returns an array of all the rooms" do
      expect(manifest.list_rooms).must_equal manifest.rooms
    end
  end

  before do
    @booker = Hotel::Booker.new
    @manifest_unavailable = @booker.manifest
    @day1 = Time.now.to_date + 3
    @day2 = @day1 + 4
    @room_ids = [2, 10, 12]
    @room_ids.each do |id|
      room = @manifest_unavailable.find_room(id: id)
      @booker.book(reservation: Hotel::Reservation.new(check_in: @day1, check_out: @day2), room: room)
    end
  end
  describe "Manifest#list_unavailable_rooms_by_date" do
    it "returns an Array" do
      expect(@manifest_unavailable.list_unavailable_rooms_by_date(date: @day1)).must_be_instance_of Array
    end

    it "correctly selects unavailable rooms" do
      comparable_rooms = @room_ids.map do |id|
        @manifest_unavailable.find_room(id: id)
      end
      expect(@manifest_unavailable.list_unavailable_rooms_by_date(date: @day1 + 1)).must_equal comparable_rooms
    end

    it "returns an empty Array if no rooms reserved for given date" do
      expect(@manifest_unavailable.list_unavailable_rooms_by_date(date: @day2 + 5)).must_equal []
    end
  end

  describe "Manifest#list_available_rooms_by_date" do
    it "returns an Array" do
      expect(@manifest_unavailable.list_available_rooms_by_date(date: @day1)).must_be_instance_of Array
    end

    it "correctly selects available rooms" do
      comparable_rooms = @manifest_unavailable.rooms.select do |room|
        !@room_ids.include?(room.id)
      end
      expect(@manifest_unavailable.list_available_rooms_by_date(date: @day1 + 1)).must_equal comparable_rooms
    end

    it "returns an empty Array if all rooms reserved for given date" do
      manifest_all_rooms_booked = Hotel::Booker.new.manifest
      (1..manifest_all_rooms_booked.rooms.length).each do |id|
        room = manifest_all_rooms_booked.find_room(id: id)
        @booker.book(reservation: Hotel::Reservation.new(check_in: @day1, check_out: @day2), room: room)
      end
      expect(manifest_all_rooms_booked.list_available_rooms_by_date(date: @day1 + 1)).must_equal []
    end
  end

  describe "Manifest#list_available_rooms_by_date_range" do
    before do
      @comparable_rooms = @manifest_unavailable.rooms.select do |room|
        !@room_ids.include?(room.id)
      end
      @day3 = @day1 + 14
      @day4 = @day1 + 21
      @room_ids.each do |id|
        room = @manifest_unavailable.find_room(id: id)
        @booker.book(reservation: Hotel::Reservation.new(check_in: @day3, check_out: @day4), room: room)
      end
    end
    it "returns an Array" do
      expect(@manifest_unavailable.list_available_rooms_by_date_range(date_range: @day1...@day2)).must_be_instance_of Array
    end
    describe "correctly selects available rooms" do
      it "date_range checked is eqaul to a room reservations(same check-in/check-outs)" do
        expect(@manifest_unavailable.list_available_rooms_by_date_range(date_range: @day1...@day2)).must_equal @comparable_rooms
      end

      it "date_range checked is overlap first part of room reservations(same check-in/ inner of check-out" do
        expect(@manifest_unavailable.list_available_rooms_by_date_range(date_range: @day1...(@day2 - 2))).must_equal @comparable_rooms
      end

      it "date_range checked is overlap end of room reservations(same check-out/ inner of check-in" do
        expect(@manifest_unavailable.list_available_rooms_by_date_range(date_range: (@day1 + 2)...@day2)).must_equal @comparable_rooms
      end

      it "date_range checked in with-in reservations(inner check-out/ inner of check-in" do
        expect(@manifest_unavailable.list_available_rooms_by_date_range(date_range: (@day1 + 1)...(@day2 - 1))).must_equal @comparable_rooms
      end

      it "date_range checked overlaps reservations(outer check-out/  outer  of check-in" do
        expect(@manifest_unavailable.list_available_rooms_by_date_range(date_range: (@day1 - 2)...(@day2 + 2))).must_equal @comparable_rooms
      end

      it "date_range checked overlaps reservations(inner check-out/  outer of check-in" do
        expect(@manifest_unavailable.list_available_rooms_by_date_range(date_range: (@day1 - 3)...(@day2 - 1))).must_equal @comparable_rooms
      end

      it "date_range checked overlaps 2 reservations" do
        expect(@manifest_unavailable.list_available_rooms_by_date_range(date_range: (@day1 + 3)...(@day4 - 1))).must_equal @comparable_rooms
      end

      it "date_range checked inbtween 2 reservations" do
        expect(@manifest_unavailable.list_available_rooms_by_date_range(date_range: (@day2 + 3)...(@day3 - 2))).must_equal @manifest_unavailable.rooms
      end

      it "date_range checked not overlapping with reservations" do
        expect(@manifest_unavailable.list_available_rooms_by_date_range(date_range: (@day1 - 7)...(@day1 - 2))).must_equal @manifest_unavailable.rooms
      end
    end
  end
end
