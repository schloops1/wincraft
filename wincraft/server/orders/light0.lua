local light0 = {} local WCServer function light0:set() WCServer = self end  light0.finalize = function() local co = require 'component'; local os = require 'os'; local thread = require 'thread'; return thread.create(function()  co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(2, 0, 0); end) end light0.run = function() local co = require 'component'; local os = require 'os'; local thread = require 'thread';	local event = require 'event'; return thread.create(function() co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(2, 0, 255); os.sleep(10); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 1); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 1); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 1); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 1); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 1); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 1); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 1); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 1); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 1); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 3); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 5); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 6); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 7); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 8); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 9); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 10); co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(0, 0, 11);  co.proxy('3d7320a4-4113-4e35-a80d-3eb8be1ce2e2').setBundledOutput(2, 0, 0);  os.sleep(1); WCServer.threadEnded('light0') end) end return light0