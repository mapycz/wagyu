CC := $(CC)
CXX := $(CXX)
CXXFLAGS := $(CXXFLAGS) -Iinclude -std=c++11
RELEASE_FLAGS := -O3 -DNDEBUG
WARNING_FLAGS := -Wall -Wextra -Weffc++ -Werror -Wsign-compare -Wfloat-equal -Wshadow -Wconversion
DEBUG_FLAGS := -g -O0 -DDEBUG -fno-inline-functions -fno-omit-frame-pointer
CLIPPER_REVISION=ac8d6bf2517f46c05647b5c19cac113fb180ffb4
ANGUS_DEFINES := -D'CLIPPER_INTPOINT_IMPL=mapbox::geometry::point<cInt>' -D'CLIPPER_PATH_IMPL=mapbox::geometry::linear_ring<cInt>' -D'CLIPPER_PATHS_IMPL=mapbox::geometry::polygon<cInt>' -D'CLIPPER_IMPL_INCLUDE=<mapbox/geometry/polygon.hpp>'


default: test

build-test: tests/* include/mapbox/geometry/* Makefile
	$(CXX) $(RELEASE_FLAGS) tests/test.cpp tests/unit/*.cpp $(WARNING_FLAGS) $(CXXFLAGS) -I ./tests -o test

build-debug: tests/* include/mapbox/geometry/* Makefile
	$(CXX) $(DEBUG_FLAGS) tests/test.cpp tests/unit/*.cpp $(WARNING_FLAGS) $(CXXFLAGS) -I ./tests -o test

build-fixture-tester-r:
	$(CXX) $(RELEASE_FLAGS) tests/fixture-tester.cpp $(WARNING_FLAGS) $(CXXFLAGS)  -o fixture-tester

build-fixture-tester:
	$(CXX) $(DEBUG_FLAGS) tests/fixture-tester.cpp $(WARNING_FLAGS) $(CXXFLAGS)  -o fixture-tester

build-fuzzer-r:
	$(CXX) $(RELEASE_FLAGS) tests/fuzzer.cpp $(WARNING_FLAGS) $(CXXFLAGS) -o fuzzer

build-fuzzer:
	$(CXX) $(DEBUG_FLAGS) tests/fuzzer.cpp $(WARNING_FLAGS) $(CXXFLAGS) -o fuzzer

quick_clip_profile: tests/quick_clip_profile.cpp
	$(CXX) $(DEBUG_FLAGS) tests/quick_clip_profile.cpp $(WARNING_FLAGS) $(CXXFLAGS) -o quick_clip_profile

# angus clipper for benchmark
./deps/clipper:
	git clone https://github.com/mapnik/clipper.git -b r496-mapnik ./deps/clipper && cd ./deps/clipper && git checkout $(CLIPPER_REVISION) && ./cpp/fix_members.sh

build-benchmark: ./deps/clipper
	$(CXX) -c $(RELEASE_FLAGS) deps/clipper/cpp/clipper.cpp $(ANGUS_DEFINES) $(CXXFLAGS) -I ./deps/clipper/cpp
	$(CXX) -c $(RELEASE_FLAGS) tests/benchmark.cpp $(ANGUS_DEFINES) $(CXXFLAGS) -I ./deps/clipper/cpp
	$(CXX) $(RELEASE_FLAGS) clipper.o benchmark.o $(CXXFLAGS) -o benchmark

build-benchmark-d: ./deps/clipper
	$(CXX) -c $(DEBUG_FLAGS) deps/clipper/cpp/clipper.cpp $(ANGUS_DEFINES) $(CXXFLAGS) -I ./deps/clipper/cpp
	$(CXX) -c $(DEBUG_FLAGS) tests/benchmark.cpp $(ANGUS_DEFINES) $(CXXFLAGS) -I ./deps/clipper/cpp
	$(CXX) $(DEBUG_FLAGS) clipper.o benchmark.o $(CXXFLAGS) -o benchmark

benchmark: build-benchmark
	./tests/run-benchmark-tests.sh ./benchmark

test: build-test build-fixture-tester-r
	./test
	./tests/run-geometry-tests.sh ./fixture-tester

debug: build-debug build-fixture-tester
	./test
	./tests/run-geometry-tests.sh ./fixture-tester

coverage: Makefile
	./scripts/coverage.sh

fuzzer: build-fuzzer
	./fuzzer

# avoids tools from getting deleted by make when it fails or you ctrl-c process
.PRECIOUS: fuzzer benchmark fixture-tester test

install:
	install -m 0755 -o root -g root -d $(DESTDIR)/usr/include/mapbox/geometry/wagyu
	install -m 0644 -o root -g root include/mapbox/geometry/wagyu/* $(DESTDIR)/usr/include/mapbox/geometry/wagyu

clean:
	rm -rf *dSYM
	rm -rf deps/
	rm -f *.o
	rm -f benchmark
	rm -f test
	rm -f fuzzer
	rm -f fixture-tester
