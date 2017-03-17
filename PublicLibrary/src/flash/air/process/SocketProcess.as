package flash.air.process
{
	import flash.desktop.NativeProcess;
	import flash.net.Socket;
	
	/**
	 *	Socket Process 第三方需要网络连接的程序 
	 * @author Administrator
	 * 
	 */	
	public class SocketProcess extends Socket
	{
		private var _exefiles:Vector.<String> = new Vector.<String>();
		private var _process:NativeProcess = new NativeProcess();
		
		public function SocketProcess(host:String=null, port:int=0)
		{
			super(host, port);
		}
		
		
		public function start(exePath:String, exeArgs:String = null,  startArgs:String = "/min", cmdPath:String = "C:/Windows/System32/cmd.exe"):void
		{
			startup(exePath, exeArgs, startArgs, cmdPath);
		}
		
		public function exit():void
		{
			for(var i:int = 0; i < _exefiles.length; i ++)
				taskkill(_exefiles[i]);
		}
	}
}