package flash.template
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.utils.setTimeout;
	
	[Event(name="change", type="flash.events.Event")]

	/**
	 *	2016巴展使用，进程列表控制对象，选择配置列表中的进程启动，或退出
	 * 
	 * 	@author Administrator
	 * 
	 * <listing version="3.0">
	 * 配置示例：可使用变量[%APPDIR%]表示应用程序安装目录
	 * 	<process delay="500" executable="">
	 * 		<!-- PPT的文件路径不能带空格，chrome全屏参数-kiosk-->
	 * 		<item id="0" executable="C:\Program Files (x86)\Microsoft Office\Office14\POWERPNT.EXE" arguments="/S assets/demo/Test_PPT.ppt" />
	 * 		<item id="1" executable="%APPDIR%/assets/demo.exe" arguments="" />
	 * 	</process>
	 * </listing>
	 * 
	 */	
	public final class ProcessListTemplate extends EventDispatcher
	{
		//配置
		private var _config:XML;
		private var _file:File;
		//进程对象
		private var _process:NativeProcess;
		private var _startInfo:NativeProcessStartupInfo;
		//参数
		private var _delay:Number = 500;
		private var _length:uint = 0;
		private var _selectedIndex:int = -1;
		
		/**
		 *	进程列表控制对象，进程的工作目录为应用程序安装目录
		 * 	@param config	列表配置，配置根节点有delay属性，有节点，节点属性有id,executable,arguments
		 */		
		public function ProcessListTemplate(processList:XML = null)
		{
			parseConfig(processList);
		}
		
		/**
		 *	分析进程配置列表 
		 * @param processList
		 */		
		public function parseConfig(list:XML):void
		{
			if(list == null)		return;
			
			if(list.children().length() > 0)
			{
				_selectedIndex = -1;
				_config = list;
				_length = _config.children().length();
				_delay = _config.hasOwnProperty("@delay") && _config.@delay != "" ? Number(_config.@delay) : _delay;
				
				/**
				 * @internal	检查进程列表是否是同一个主执行文件
				 */
				if(_config.hasOwnProperty("@executable") && _config.@executable != "")
				{
					var path:String = _config.@executable.toString().replace("%APPDIR%", File.applicationDirectory.nativePath).replace(/\\/g, "/");
					_file = new File(path);
					
					if(!_file.exists)	_file = null;
				}
				else
				{
					_file = null;
				}
				
				//Process
				if(_process == null)
				{
					_process = new NativeProcess();		
					_process.addEventListener(NativeProcessExitEvent.EXIT, onNativeProcessExitHandler);
					_process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onNativeProcessDataHandler);
				}
				
				if(_startInfo == null)
				{
					_startInfo = new NativeProcessStartupInfo();
					_startInfo.workingDirectory = File.applicationDirectory;
				}
			}
			else
			{
				trace("进程列表配置无资源或为空.");
			}
		}
		
		/**
		 *	进程退出事件处理 
		 * @param e
		 */		
		private function onNativeProcessExitHandler(e:NativeProcessExitEvent):void
		{
			trace("Native Process Exiting ... ");
			_selectedIndex = -1;
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		private function onNativeProcessDataHandler(e:ProgressEvent):void
		{
			trace("Got: ", _process.standardOutput.readUTFBytes(_process.standardOutput.bytesAvailable)); 
		}
		
		/**
		 *	跟据索引启动进程，如果当前进程正在运行，则会退出当前进程，然后等待delay毫秒后，启动选择索引的进程
		 * @param index	进程配置索引
		 */		
		public function start(index:int):void
		{
			if(_process == null)	return;
			//如果与当前正在运行的进程一样，则返回，不处理
			if(_selectedIndex == index)	return;
			
			//如果进程正在运行，则退出，delay毫秒后重新启动新的进程
			if(_process.running)
			{
				exit();
				setTimeout(start, _delay, index);
				return;
			}
			
			var cfg:XML = _config.children().(@id == index)[0];
			if(cfg == null)		return;		//配置不存在，处理个毛
			
			/**
			 * @internal	检查是否有例外的执行文件
			 */
			var file:File;
			if(cfg.hasOwnProperty("@executable") && cfg.@executable != "")
			{
				var path:String = cfg.@executable.toString().replace("%APPDIR%", File.applicationDirectory.nativePath).replace(/\\/g, "/");
				file = new File(path);
			}
			
			_startInfo.executable = (file != null && file.exists) ? file : _file;
			
			if(cfg.hasOwnProperty("@arguments") && cfg.@arguments != "")
				_startInfo.arguments = getProcessArguments(cfg.@arguments);
			
			//启动进程
			_process.start(_startInfo);
			
			_selectedIndex = index;
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
			
		/**
		 *	 尝试退出本机进程
		 * 	@param force	应用程序是否应尝试强制退出本机进程
		 */
		public function exit(force:Boolean=false):void
		{
			if(_process == null)	return;
			if(_process.running)	_process.exit(force);
			
			_selectedIndex = -1;
			//this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		/**
		 *	返回当前进程的配置 
		 * 	@return 
		 */		
		public function get processConfig():XML
		{
			return _selectedIndex == -1 ? null : _config.children().(@id == _selectedIndex)[0];
		}
		
		/**
		 *	列表长度 
		 * 	@return 
		 */		
		public function get length():int{		return _length;		}
		
		/**
		 *	返回当前正在运行进程的索引 
		 * 	@return 
		 */		
		public function get selectedIndex():int{		return _selectedIndex;		}
		
		/**
		 *	进程对象是否正在运行 
		 * 	@return 
		 */		
		public function get running():Boolean	{		return _process && _process.running;	}
		
		/**
		 *	获取进程参数 
		 * @param args
		 * @return 
		 */		
		public static function getProcessArguments(args:String):Vector.<String>
		{
			var arg:String = "";
			var arr:Array = args.split(" ");
			var arguments:Vector.<String> = new Vector.<String>(arr.length, true);
			
			for(var i:int = 0; i < arr.length; i ++)
			{
				arg = arr[i];
				
				if(arg.indexOf("%APPDIR%") != -1)
					arg = arg.replace("%APPDIR%", File.applicationDirectory.nativePath).replace(/\\/g, "/");
				
				arguments[i] = arg;
			}
			
			return arguments;
		}
	}
}