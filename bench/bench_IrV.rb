require File.expand_path(File.join(File.dirname(__FILE__), "bench_helper"))

module LibTest
  extend FFI::Library
  ffi_lib LIBTEST_PATH
  attach_function :ffi_bench, :bench_s32_v, [ :int ], :void
  def self.rb_bench(i0); nil; end
end
unless RUBY_PLATFORM == "java" && JRUBY_VERSION < "1.3.0"
  require 'dl'
  require 'dl/import'
  module LibTest
    if RUBY_VERSION >= "1.9.0"
      extend DL::Importer
    else
      extend DL::Importable
    end
    dlload LIBTEST_PATH
    extern "void bench_s32_v(int)"
  end
end

puts "Benchmark [ :int ], :void performance, #{ITER}x calls"
10.times {
  puts Benchmark.measure {
    ITER.times { LibTest.ffi_bench(0) }
  }
}


unless RUBY_PLATFORM == "java" && JRUBY_VERSION < "1.3.0"
puts "Benchmark DL void bench(int) performance, #{ITER}x calls"
10.times {
  puts Benchmark.measure {
    ITER.times { LibTest.bench_s32_v(0) }
  }
}
end
puts "Benchmark Invoker.call [ :int  ], :void performance, #{ITER}x calls"

invoker = FFI.create_invoker(LIBTEST_PATH, 'bench_s32_v', [ :int ], :void)
10.times {
  puts Benchmark.measure {
    ITER.times { invoker.call(1) }
  }
}

f = FFI::Function.new(:void, [ :int ], invoker, { :ignore_errno => true, :convention => :default })
puts "Benchmark [ :int ], :void no-errno performance, #{ITER}x calls"
module NoErrno ;end
f.attach(NoErrno, "ffi_bench")
10.times {
  puts Benchmark.measure {
    ITER.times { NoErrno.ffi_bench(0) }
  }
}

puts "Benchmark ruby method(1 arg)  performance, #{ITER}x calls"
10.times {
  puts Benchmark.measure {
    ITER.times { LibTest.rb_bench(0) }
  }
}

