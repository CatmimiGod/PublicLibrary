package flash.air.process
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.NativeProcessExitEvent;
	import flash.filesystem.File;
	import flash.events.ProgressEvent;
	
	/**
	 * 本地进程控制类，继承NativeProcess。
	 * 
	 * <p>主要添加自动启动进程，写入字符参数方法，进程退出后强制重启进程。</p>
	 * <p>最后更新时间：2012-11-30 huang</p>
	 * 
	 * @playerversion AIR 2.0
	 */ 
	public class LocalProcess extends NativeProcess
	{
		/**
		 * 是否永久运行，禁止退出进程。当进程退出时，自动重新启动进程。 
		 * @playerversion AIR 2.0
		 * @default false
		 */ 
		public var banexit:Boolean = false;
		
		private var info:NativeProcessStartupInfo;
		
		/**
		 * 构造函数。
		 * 
		 * @param executable:File 可执行程序文件
		 * @param arguments:Vector.&lt;String&gt; 可执行程序运行参数
		 * 
		 * @throws ArgrmentError 文件不存在
		 * @playerversion AIR 2.0
		 */ 
		public function LocalProcess(executable:File, arguments:Vector.<String> = null):void
		{
			super();
			
			if(executable.exists)
			{
				info = new NativeProcessStartupInfo();
				info.executable = executable;
				
				if(arguments && arguments.length > 0)
					info.arguments = arguments;
			
				super.start(info);			
				super.addEventListener(NativeProcessExitEvent.EXIT, onProcessExitHandler);
				//super.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onStandardOutData);
			}
			else
			{
				throw new ArgumentError("LocalProcess类,executable参数，文件不存在！！");
			}
		}
		
		private function onStandardOutData(e:ProgressEvent):void
		{
			trace("Got: ", super.standardOutput.readUTFBytes(super.standardOutput.bytesAvailable)); 
		}
		
		/**
		 * 向进程输入参数。
		 * 
		 * @param arg:String 进程参数。
		 * @playerversion AIR 2.0
		 */ 
		public function writeUTFBytes(arg:String):void
		{
			super.standardInput.writeUTFBytes(arg + "\n");
		}
		
		/**
		 * 进程退出事件处理。
		 * @playerversion AIR 2.0
		 */ 
		protected function onProcessExitHandler(e:NativeProcessExitEvent):void
		{
			trace("Process Exit...");
			if(banexit)
			{
				super.start(this.info);
			}
			else
			{
				if(super.running)
					super.exit();
				
				info = null;
				super.removeEventListener(NativeProcessExitEvent.EXIT, onProcessExitHandler);
			}
		}
	}
}