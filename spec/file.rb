
require 'securerandom'

class File
	TMP = "/tmp"
	
	def self.buffer(mode = 'w+', root: TMP)
		path = File.join(root, SecureRandom.hex(32))
		file = File.open(path, mode)
		
		File.unlink(path)
		
		return file unless block_given?
		
		begin
			yield file
		ensure
			file.close
		end
	end
end
