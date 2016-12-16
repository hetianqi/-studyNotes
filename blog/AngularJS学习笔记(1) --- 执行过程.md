---
title: AngularJS学习笔记(1) --- 执行过程
date: 2016/12/14 10:41:23
tags: AngularJS
---

# 前言

由于在博客系统的开发中和近期工作中的前端框架主要使用 AngularJS ,因此在这里记录学习和使用 AngularJS 的过程中遇到的一些需要记录的点。特别说明，本文并非教程。

## 执行过程

弄清楚 AngularJS 的执行过程是很重要的，这样你才能在正确的时机做正确的事。在这点上我就犯过错误，话不多说，直接上代码：

```JavaScript
var app = angular.module('app', ['ngRoute']);

app.config([
	'$routeProvider',
	'$http',
	'$q',
	function ($routeProvider, $http, $q) {
		$routeProvider
			.when('/', {
				template: '123',
				resolve: {
					auth: function () {
						// do stuff
					}
				}
			});
	}
]);
```
报错啦！！！上面的代码在启动阶段就会报下图所示的错误：

![启动报错](http://ww2.sinaimg.cn/large/765147e8gw1fasdey55u6j20pb0e4tcl.jpg)

乍一看都不知道错在哪里，经过分析才知道，module.config 方法是在 on module loading，即模块加载过程中执行的，此时 $http 和 $q 等服务都还没有创建成功，不能当做依赖项注入到 module.config 方法中。

<!--- more --->

回到主题，AngularJS 框架的执行过程大致如下所示：

![执行过程](http://ww4.sinaimg.cn/large/765147e8gw1fasf3cmrf1j20uk0go76a.jpg)

配合源码会理解的更清楚：
```JavaScript
bindJQuery();

publishExternalAPI(angular);

jqLite(document).ready(function() {
	angularInit(document, bootstrap);
});
```

具体代码可以到源码中查看，这里简要说明一下：

*	`bindJQuery()` 尝试绑定jQuery对象，如果没有则采用内置的jqLite。
*	`publishExternalAPI(angular)` 初始化 `angular` 环境，为 `angular` 对象注册 `module`，`forEach`，`extend` 等方法。
	
	关于 `module` 方法，在此要说明一下：
    
    `angular.module('myApp')` 只传一个参数，为getter操作，返回 `moduleInstance` 对象，而 angular.module('myApp',[]) 传入两个参数，为setter操作，也返回 moduleInstance 对象
    
    ```JavaScript
	var moduleInstance = {
		// Private state
		\_invokeQueue: invokeQueue,
		\_runBlocks: runBlocks,
		requires: requires,
		name: name,
		provider: invokeLater('$provide', 'provider'),
		factory: invokeLater('$provide', 'factory'),
		service: invokeLater('$provide', 'service'),
		value: invokeLater('$provide', 'value'),
		constant: invokeLater('$provide', 'constant', 'unshift'),
		animation: invokeLater('$animateProvider', 'register'),
		filter: invokeLater('$filterProvider', 'register'),
		controller: invokeLater('$controllerProvider', 'register'),
		directive: invokeLater('$compileProvider', 'directive'),
		config: config,
		run: function(block) {
			runBlocks.push(block);
			return this;
		}
	}
	```
*	`angularInit(document, bootstrap)` 方法内容如下：
	
	```JavaScript
	function angularInit(element, bootstrap) {
	  var elements = [element],
	      appElement,
	      module,
	      names = ['ng:app', 'ng-app', 'x-ng-app', 'data-ng-app'],
	      NG_APP_CLASS_REGEXP = /\sng[:\-]app(:\s*([\w\d_]+);?)?\s/;
	
	  function append(element) {
	    element && elements.push(element);
	  }
	
	  forEach(names, function(name) {
	    names[name] = true;
	    append(document.getElementById(name));
	    name = name.replace(':', '\\:');
	    if (element.querySelectorAll) {
	      forEach(element.querySelectorAll('.' + name), append);
	      forEach(element.querySelectorAll('.' + name + '\\:'), append);
	      forEach(element.querySelectorAll('[' + name + ']'), append);
	    }
	  });
	
	  forEach(elements, function(element) {
	    if (!appElement) {
	      var className = ' ' + element.className + ' ';
	      var match = NG_APP_CLASS_REGEXP.exec(className);
	      if (match) {
	        appElement = element;
	        module = (match[2] || '').replace(/\s+/g, ',');
	      } else {
	        forEach(element.attributes, function(attr) {
	          if (!appElement && names[attr.name]) {
	            appElement = element;
	            module = attr.value;
	          }
	        });
	      }
	    }
	  });
	  if (appElement) {
	    bootstrap(appElement, module ? [module] : []);
	  }
	}
	```
	遍历names，通过 document.getElementById(name) 或者是 querySelectorAll(name) 检索到 element 后存入 elements 数组中，最后获取到 appElement 以及module。
	
	举个例子：我们一般会在文档开始的html标签上写 ng-app="myApp"，通过以上方法，我们最后可以得到名为 myApp 的 module，后调用 bootstrap(appElement,[module]);
	
	bootstrap 中需要重点关注 doBootstrap 方法：
	
	```JavaScript
	var doBootstrap = function() {
	  element = jqLite(element);
	
	  if (element.injector()) {
	    var tag = (element[0] === document) ? 'document' : startingTag(element);
	    throw ngMinErr('btstrpd', "App Already Bootstrapped with this Element '{0}'", tag);
	  }
	  //通过上面分析我们知道此时 modules 暂时是这样的： modules = ['myApp'];
	  modules = modules || [];
	  //添加$provide这个数组
	  modules.unshift(['$provide', function($provide) {
	    $provide.value('$rootElement', element);
	  }]);
	  //添加 ng这个 module ,注意：1857行  我们注册过ng 这个module，并在1854行 我们注册过 它的依赖模块'ngLocale'，
	  //angularModule('ngLocale', []).provider('$locale', $LocaleProvider); 我们注册过ngLocale这个module
	  modules.unshift('ng');
	  //调用createInjector(module) 此时：module为：
	  //['ng',['$provide',function(){}],'myApp']  两个type为string，一个为array
	  var injector = createInjector(modules);
	  injector.invoke(['$rootScope', '$rootElement', '$compile', '$injector', '$animate',
	     function(scope, element, compile, injector, animate) {
	      scope.$apply(function() {
	        element.data('$injector', injector);
	        compile(element)(scope);
	      });
	    }]
	  );
	  return injector;
	};
	```

最后通过 $apply 将作用域转入 angular 作用域，所谓angular作用域是指：angular采用dirity-check方式进行检测，达到双向绑定。

再利用 compile 函数编译整个页面文档，识别出 directive，按照优先级排序，执行他们的 compilie 函数，最后返回 link function 的结合，通过 scope 与模板连接起来，形成一个即时，双向绑定。

至此，AngularJS 的执行过程也就告一段落了。