package 
{
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.URLVariables;
	import flash.utils.getDefinitionByName;
	
	/**
	 * ActionScript
	 * 
	 * @author Administrator
	 */	
	public final class AS
	{
		/**
		 *	 call对象(或子级对象)的公共函数或属性.
		 * 
		 * @param model			模型对象或类的类对象引用
		 * @param properties	模型对象可访问的属性或方法，或可访问的子级对象的属性或方法
		 * @param args			属性或方法的参数，默认为 null
		 * @param ignoreError	是否忽略执行错误，默认为 false
		 * 
		 * @throws Error	函数或属性执行错误
		 * @return 				返回对象的属性值，或函数执行的返回对象，属性错误和参数错误会返回null对象
		 * 
		 * @example 示例：
		 * <listing version="3.0">
		 * AS.callProperty(this, "mc.gotoAndPlay", 2, true);	//调用公共方法 mc.gotoAndPlay(2);
		 * AS.callProperty(this, "mc.visible", false, true);	//设置公共属性 mc.visible = false;
		 * AS.callProperty("flash.desktop.NativeApplication", "nativeApplication.exit", null, true);	//调用静态的公共方法或属性 
		 * </listing>
		 */		
		public static function callProperty(model:Object, properties:String, args:Object = null, ignoreError:Boolean = false):*
		{
			if(model == null || properties == null || properties == "")	return null;
			var tm:Object = (model is String && model.indexOf(".") != -1) ? getDefinitionByName(model.toString()) : model;
			
			var props:Array = properties.split(".");
			var pORf:String = props.splice(props.length - 1, 1);	//提出属性或方法名称 propertyORfunction
			
			/**	@internal	查找公共子级对象	*/
			for(var i:int = 0; i < props.length; i ++)
			{
				if(tm.hasOwnProperty(props[i]))
					tm = tm[props[i]];
				else
					return throwError("ReferenceError: Error #1069 不存在可访问的子级对象:" + props[i] + " [" + properties + "]", ignoreError);;
			}
			
			/**	@internal	检查对象是否已经定义了指定的属性		*/
			if(!tm.hasOwnProperty(pORf))
				return throwError("ReferenceError: Error #1069 对象或子级对象不存在的属性或方法:" + pORf +" [" + properties + "]", ignoreError);
			
			/**	@internal	检查对象属性是函数还是属性对象		*/
			if(tm[pORf] is Function)
			{
				var argArray:* = args == null ? null : args is String ? args.split(",") : args is Array ? args : [args];
				
				//抛出函数执行错误
				try
				{
					return tm[pORf].apply(tm, argArray);
				} 
				catch(error:Error) 
				{
					return throwError(error.name + "函数执行错误：函数[" + properties + "] 参数[" + argArray + "]\n" + error.message, ignoreError);
				}
			}
			else
			{
				//抛出属性设置错误
				if(args != null)
				{
					try
					{
						tm[pORf] = args;
					} 
					catch(error:Error) 
					{
						return throwError(error.name + ":属性读写失败:属性[" + pORf + "] 值[" + args + "]\n" + error.message, ignoreError);
					}
				}
				return tm[pORf];
			}
			
			return null;
			
			//抛出错误信息
			function throwError(message:String, ignoreError:Boolean):*
			{
				if(ignoreError)
					trace(message);
				else
					throw new Error(message);
				
				return null;
			}
		}
		
		/**
		 *	包含名称/值对的 URL 编码的字符串，非严谨值对编码字符串。<br/>
		 *  与URLVariables类有所区别：1.同一个变量，重复调解析赋值，不会生成数组，而是替换之前的值；2.名称/值对没有URLVariables严谨
		 * @param source
		 * @return 返回对象
		 * 
		 * @example 示例：
		 * <listing version="3.0">
		 * var obj:Object = decodeURLVariables("a=1&amp;b=2&amp;c=a=1");
		 * </listing>
		 */		
		public static function decodeURLVariables(source:String):URLVariables
		{
			if(source == null)	return null;
			
			var data:URLVariables = new URLVariables();
			
			var prop:String;
			var value:String;
			var array:Array = source.split("&");
			
			var temp:String;
			var index:int = -1;
			
			for(var i:int = 0; i < array.length; i ++)
			{
				temp = array[i];
				index = temp.indexOf("=");
				
				if(index != -1)	
				{
					prop = temp.substr(0, index);
					value = temp.substr(index + 1, temp.length);
					
					data[prop] = value;
				}
			}
			
			return data;
		}
		
		/**
		 *	以cmd命令行start命令启动第三方程序，主程序退出时第三方程序也会自动退出。
		 * 
		 * @param exePath	执行文件路径，相对路径或绝对路径
		 * @param startArgs	start命令行参数
		 * @param cmdPath	cmd文件路径
		 * 
		 * @throws ArgumentError	参数错误
		 * 
		 */		
		public static function startup(exePath:String, startArgs:String = "/min", cmdPath:String = "C:/Windows/System32/cmd.exe"):void
		{
			if(exePath == null)
				throw new ArgumentError("函数 startup 参数 exePath 不参为空.");
			
			var cmdFile:File = new File(cmdPath);
			if(!cmdFile.exists)
				throw new ArgumentError("cmd执行文件：" + cmdPath + " 不存在.");
			
			var path:String = exePath.indexOf(":") == -1 ? File.applicationDirectory.nativePath + "/" + exePath : exePath;
			path = path.replace(/\\/ig, "/").replace(/\/\//ig, "/");
			
			if(path.indexOf(".exe") == -1 || !(new File(path).exists))
				throw new ArgumentError("exe执行文件：" + path + " 不存在.");
			
			var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			startupInfo.executable = cmdFile;
			var process:NativeProcess = new NativeProcess();
			process.start(startupInfo);
			
			var drive:String = path.substr(0, 2);								//盘符
			var filePath:String = path.substring(0, path.lastIndexOf("/"));		//路径
			var fileName:String = path.substr(path.lastIndexOf("/") + 1);		//文件
			//trace(drive, filePath, fileName);
			
			process.standardInput.writeMultiByte(drive + "\n", "gb2312");
			process.standardInput.writeMultiByte("cd " + filePath + "\n", "gb2312");
			process.standardInput.writeMultiByte("start " + (startArgs != null ? startArgs + " " + fileName : fileName) + "\n", "gb2312");
			
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, function(e:Event):void 
			{
				if(!process.running)	return;
				
				process.standardInput.writeMultiByte("taskkill /f /im " + fileName + "\n", "gb2312");
				process.standardInput.writeMultiByte("exit\n", "gb2312");
			});
		}
	}
}