package flash.template
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.template.DemoApplicationTemplate;
	import flash.standard.IContentPagesList;
	
	/**
	 * 	加载列表模版，继承DemoApplicationTemplate
	 * @author Administrator
	 */	
	public class LoaderListTemplate extends DemoApplicationTemplate implements IContentPagesList
	{
		private var _loader:Loader;
		
		protected var _homePage:DisplayObject;
		protected var _contentPage:DisplayObject;
		protected var _controlUI:MovieClip;
		
		private var _length:uint = 0;
		private var _selectedIndex:int = -1;
		
		//	缓存列表
		private var _cacheList:Vector.<DisplayObject>;
		
		/**
		 *	Constructor. 
		 */		
		public function LoaderListTemplate()
		{
			super.loaderConfiguration("assets/config.xml");
		}
		
		/**	initialize	*/
		override protected function initialize():void
		{
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderContentComplete);
			
			/**
			 *	@internal	加载控制UI 
			 */
			if(configData.content.hasOwnProperty("@controlUI") && configData.content.@controlUI != "")
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderControlUIComplete, false, 0, true);
				loader.load(new URLRequest(configData.content.@controlUI));
			}
			
			languageChanged();
		}
		
		/**	语言切换处理	*/
		override protected function languageChanged():void
		{
			_length = configData.content[language].children().length();
			//_length = configData.content.hasOwnProperty(language) ? configData.content[language].children().length() : configData.content.children().length();
			_length = configData.content.children().length();
			
			if(_cacheList != null)
			{
				for(var i:int = 0; i < _cacheList.length; i ++)
					_cacheList[i] = null;
				_cacheList = null;
			}
			_cacheList = new Vector.<DisplayObject>(_length, true);
			
			/**
			 * @internal	如果没有主页，就加载子级列表内容
			 */
			//if(configData.content[language].hasOwnProperty("@homePage") && configData.content[language].@homePage != "")
			if(configData.content.hasOwnProperty("@homePage") && configData.content.@homePage != "")
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderHomePageComplete, false, 0, true);
				//loader.load(new URLRequest(configData.content[language].@homePage));
				loader.load(new URLRequest(configData.content.@homePage));
			}
			else
			{
				if(_selectedIndex == -1)	_selectedIndex = 0;
				
				loadPage(_selectedIndex);
			}
			
			if(_controlUI != null && _controlUI.hasOwnProperty("setLanguage"))
				_controlUI.setLanguage(language);
		}
		
		/**
		 *	加载控制UI完成 
		 * @param e
		 */		
		protected function onLoaderControlUIComplete(e:Event):void
		{
			if(_controlUI != null)
			{
				this.removeChild(_controlUI);
				_controlUI = null;
			}
			
			_controlUI = e.target.content;
			this.addChild(_controlUI);
			
			if(_controlUI.hasOwnProperty("setTarget"))
				_controlUI.setTarget(this);
			
			if(_controlUI.hasOwnProperty("setLanguage"))
				_controlUI.setLanguage(language);
			
			trace("加载控制UI完成 .... ");			
			e.target.removeEventListener(Event.COMPLETE, onLoaderControlUIComplete);
			//e.target.loader = null;
		}
		
		/**
		 *	加载背景内容完成
		 * @param e
		 */		
		protected function onLoaderHomePageComplete(e:Event):void
		{
			this.addChildAt(e.target.content, 0);
			if(_controlUI != null)
				this.setChildIndex(_controlUI, this.numChildren - 1);
			
			if(_homePage != null)
			{
				this.removeChild(_homePage);
				_homePage = null;
			}
			
			_homePage = e.target.content;
			//this.addChildAt(_homePage, 0);
			
			if(_homePage is Bitmap)
				(_homePage as Bitmap).smoothing = true;
			
			trace("加载背景或主页完成 .... ");
			e.target.removeEventListener(Event.COMPLETE, onLoaderHomePageComplete);
			//e.target.loader = null;
			
			loadPage(_selectedIndex);
		}
		
		/**
		 *	加载子级页面内容完成
		 * @param e
		 */		
		protected function onLoaderContentComplete(e:Event):void
		{
			//var item:XML = configData.content[language].children()[_selectedIndex];
			var item:XML = configData.content.children()[_selectedIndex];
			var cache:Boolean = item.hasOwnProperty("@cache") && item.@cache.toLowerCase() == "true";
			
			if(cache)
				_cacheList[_selectedIndex] = e.target.content;
			
			addContentPage(e.target.content);
		}
		
		/**
		 * 添加内容页面
		 */
		protected function addContentPage(content:DisplayObject):void
		{
			if(content.hasOwnProperty("initialize"))	content["initialize"]();
			this.addChild(content);
			
			if(_controlUI != null)
				this.setChildIndex(_controlUI, this.numChildren - 1);
			
			if(_contentPage != null)
			{
				this.removeChild(_contentPage);
				if(_contentPage.hasOwnProperty("dispose"))	_contentPage["dispose"]();
				_contentPage = null;
			}
			_contentPage = content;
			
			if(_contentPage is Bitmap)
				(_contentPage as Bitmap).smoothing = true;
			
			trace("内容页面加载完成 ..... " + _selectedIndex + "/" + _length);
		}
		
		/**
		 *	加载指定的页面 
		 * @param index	加载的页面索引，-1表示返回主面
		 */	
		public function loadPage(index:int):void
		{
			if(index < -1 && index > _length)
				throw new ArgumentError("加载内容索引超出范围...." + index);
			
			if(_selectedIndex != index)
				_selectedIndex = index;
			
			//_loader.unload();
			_loader.unloadAndStop();
			this.dispatchEvent(new Event(Event.CHANGE));
			
			/**
			 * @internal	-1表示回到主界面，清除当前内容页面
			 */
			if(index == -1)
			{
				if(_contentPage != null)
					this.removeChild(_contentPage);
				
				_contentPage = null;				
				return;
			}
			
			if(_cacheList[index] != null)
			{
				addContentPage(_cacheList[index]);
				return;
			}
			
			//var url:String = configData.content[language].children()[index].@url;
			var url:String = configData.content.children()[index].@url;
			if(url == null || url == "")
				throw new ArgumentError("配置错误，指定的路径错误！ language:" + language + "  id:" + index + "  url:" + url);
			
			url = url.replace(/%LANGUAGE%/ig, language);
			trace("加载内容：language:" + language + "  id:" + index + "  url:" + url);
			_loader.load(new URLRequest(url));
		}
		
		/**
		 *	下一页 
		 */		
		public function nextPage():void
		{
			var index:int = _selectedIndex + 1 > _length - 1 ? 0 : _selectedIndex + 1;
			
			loadPage(index);
		}
		
		/**
		 *	上一页 
		 */		
		public function prevPage():void
		{
			var index:int = _selectedIndex - 1 < 0 ? _length - 1 : _selectedIndex - 1;
			
			loadPage(index);
		}
		
		/**	返回主页面内容	*/
		public function get homePage():Object{	return _homePage;		}
		
		/**	返回当前页面内容 	*/		
		public function get currentPage():Object{		return _contentPage;		}
		
		/**	返回控制UI对象		 */
		public function get controlUI():MovieClip{	return _controlUI;		}
		
		
		/**	返回子级内容列表长度	 */		
		public function get length():uint{		return _length;		}
		
		/**	获取当前显示的页面索引	*/		
		public function get selectedIndex():int{		return _selectedIndex;		}
		
	}
}