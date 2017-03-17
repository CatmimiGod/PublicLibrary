package flash.air.process
{
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	/**
	 *	Command 命令进程对象 
	 * @author Administrator
	 */	
	public final class CommandProcess extends NativeProcess
	{
		private var _banexit:Boolean = true;
		private var _info:NativeProcessStartupInfo;
		
		/**
		 *	Constructor. 
		 */		
		public function CommandProcess(path:String = "C:/Windows/System32/cmd.exe")
		{
			super();
			
			var cmdFile:File = new File(path);
			if(cmdFile.exists)
			{
				_info = new NativeProcessStartupInfo();
				_info.executable = cmdFile;
				
				super.start(_info);			
				super.addEventListener(NativeProcessExitEvent.EXIT, onProcessExitHandler, false, 0, true);
				super.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onStandardOutData, false, 0, true);
				
				//super.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onStandardErrorHandler);
				//super.addEventListener(IOErrorEvent.STANDARD_INPUT_IO_ERROR, onStandardErrorHandler);
				//super.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onStandardErrorHandler);
				
				//NativeApplication.nativeApplication.addEventListener(Event.EXITING, onNativeApplicationExitHandler);
			}
			else
			{
				throw new ArgumentError("CommandProcess::cmd.exe文件路径错误！！");
			}
		}
		
		/**
		 * 进程退出事件处理。
		 * @playerversion AIR 2.0
		 */ 
		protected function onProcessExitHandler(e:NativeProcessExitEvent):void
		{
			_banexit ? super.start(this._info) : dispose();
		}
		
		/**
		 *	@private 
		 * 应用程序退出事件处理
		 */		
		private function onNativeApplicationExitHandler(e:Event):void
		{
			dispose();
		}
		
		/**
		 *	退出并清理进程信息 
		 */		
		public function dispose():void
		{
			trace("CommandProgress Exiting...");
			_banexit = false;
			
			super.removeEventListener(NativeProcessExitEvent.EXIT, onProcessExitHandler);
			super.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onStandardOutData);			
			//NativeApplication.nativeApplication.removeEventListener(Event.EXITING, onNativeApplicationExitHandler);
			
			if(super.running)
				super.exit();
			
			_info = null;
			_result = null;
		}
			
		private var _result:Function = null;
		private var _bytes:ByteArray = new ByteArray();
		
		/**
		 *	执行命令行 
		 * @param cmd
		 * @param result
		 */		
		public function execute(cmd:String, result:Function = null):void
		{
			if(super.running)
			{
				_bytes.clear();
				super.standardOutput.readBytes(_bytes, 0, super.standardOutput.bytesAvailable);
				
				_result = result;
				cmd = cmd.lastIndexOf("\n") == cmd.length - 1 ? cmd : cmd + "\n";
				
				_bytes.clear();
				_bytes.writeMultiByte(cmd, "gb2312");
				super.standardInput.writeBytes(_bytes, 0, _bytes.length);
			}
			else
			{
				trace("cmd进程已经终止.");
			}
		}
		
		private function onStandardOutData(e:ProgressEvent):void
		{
			//var bytes:ByteArray;
			//super.standardOutput.readBytes(bytes, 0, super.standardOutput.bytesAvailable);
			
			//var data:String = super.standardOutput.readUTFBytes(super.standardOutput.bytesAvailable);
			var data:String = super.standardOutput.readMultiByte(super.standardOutput.bytesAvailable, "gb2312");
			//trace("Got: ", data);
			
			if(_result != null)
				_result(data);
		}
		
		private function onStandardErrorHandler(e:IOErrorEvent):void
		{
			trace(e);
		}
		
	}
}