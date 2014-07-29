require_relative './worker'

worker = JCukeForker::Worker.new *$ARGV
worker.register
worker.run
worker.close
