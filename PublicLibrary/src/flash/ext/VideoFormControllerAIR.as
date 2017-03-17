package flash.ext
{
	import flash.air.process.startup;

	/**
	 *	针对AIR程序，添加了一个启动功能 
	 * @author Administrator
	 * @playversion AIR 1
	 */	
	public class VideoFormControllerAIR extends VideoFormController
	{
		/**
		 *	Constructor. 
		 * @param module
		 * @param port
		 * @param address
		 * 
		 * @playversion AIR 1
		 */		
		public function VideoFormControllerAIR(module:Object=null, port:int=2010, address:String="127.0.0.1")
		{
			super(module, port, address);
		}
		
		/**
		 * 启动VideoForm.exe程序(使用cmd命令行启动) ，退出请使用dispose();
		 * @param videoFormPath
		 * @param cmdPath
		 */
		public function startVideoForm(videoFormPath:String, cmdPath:String = "C:/Windows/System32/cmd.exe"):void
		{
			if(videoFormPath == null)	return;
			startup(videoFormPath, null, null, cmdPath);
		}
		
	}
}