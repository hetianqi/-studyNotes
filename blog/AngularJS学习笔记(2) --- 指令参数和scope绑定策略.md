---
title: AngularJS学习笔记(2) --- 指令参数和scope绑定策略
date: 2017-2-14 17:53:00
tags: AngularJS, JavaScript
---

# 引言

指令(Directive)可以说是 `AngularJS` 的核心，而其开发也是比较困难的，本文主要介绍指令的一些参数和scope的绑定策略。

# 参数

从 AngularJS 的官方文档中看到指令的参数如下：

```JavaScript
{
    priority: 0,
    template: '<div></div>', // or // function(tElement, tAttrs) { ... },
    // or
    // templateUrl: 'directive.html', // or // function(tElement, tAttrs) { ... },
    transclude: false,
    restrict: 'A',
    scope: false,
    controller: function($scope, $element, $attrs, $transclude, otherInjectables) { ... },
    controllerAs: 'stringAlias',
    require: 'siblingDirectiveName', // or // ['^parentDirectiveName', '?optionalDirectiveName', '?^optionalParent'],
    compile: function compile(tElement, tAttrs, transclude) {
      return {
        pre: function preLink(scope, iElement, iAttrs, controller) { ... },
        post: function postLink(scope, iElement, iAttrs, controller) { ... }
      }
      // or
      // return function postLink( ... ) { ... }
    },
    // or
    // link: {
    //  pre: function preLink(scope, iElement, iAttrs, controller) { ... },
    //  post: function postLink(scope, iElement, iAttrs, controller) { ... }
    // }
    // or
    // link: function postLink( ... ) { ... }
}
```
<!-- more -->

下面详细讲解每个参数。

## `priority(Number)`

指令执行的优先级，用于多个指令同时作用于同一个元素时。例如：

```HTML
<select>
	<option ng-repeat="i in [1, 2]" ng-bind="i"></option>
</select>
```

上面的例子中，`ng-repeat` 指令和 `ng-bind` 指令同时作用于 `option` 元素，由于 `ng-repeat` 的 priority 为1000，`ng-bind` 的 priority 为0，因此先执行 `ng-repeat`，然后变量 i 的值才能用于 ng-bind 中。

## `template(String or Function)`

HTML模板内容，用于下列情况之一：

* 替换元素的内容（默认情况）。

* 替换元素本身（如果 replace 选项为 true）。

* 将元素的内容包裹起来（如果 transclude 选项为 true，后面会细说）。

值可以是：

* 一个 HTML 字符串。例如：`<div>my name is {{name}}</div>`。

* 一个函数，接收两个参数 tElement(元素本身) 和 tAttrs(元素的属性集合)，返回 HTML 字符串。

## `templateUrl(String or Function)`

templateUrl 和 template 作用相同，但模板内容是从 $templateCache 服务或远程 url 加载。

值可以是：

* 一个字符串，`AngularJS` 会先从 `$templateCache` 中查找是否缓存了对应值，如果没有则尝试 ajax 加载。例如：在页面中有如下 script：
	```HTML
	<script type="text/ng-template" id="Hello.html">
		<p>Hello</p>
	</script>
	```
AngularJS 会将 `type="text/ng-template"` 的 `script` 标签中的内容以 id 值为 key 缓存到 $templateCache 服务中，此时可以设置 `templateUrl: 'Hello.html'`。

* 一个函数，接收两个参数 tElement(元素本身) 和 tAttrs(元素的属性集合)，返回 url 地址。

## `transclude(Boolean)`

官方文档的解释为：编译元素的内容，使其在指令内部可用。该选项一般和 `ng-transclude` 指令一起使用。

如果 transclude 设置为 true，则元素的内容会被放到模板中设置了 `ng-transclude` 指令的元素中。例如：

```JavaScript
app.directive('testTransclude', [
	function () {
		return {
			restrict: 'E',
			transclude: true,
			template:
				'<div>\
					<p>指令内部段落</p>\
					<div ng-transclude></div>\
				</div>'
		};
	}
]);
```

```HTML
<test-transclude>
	<p>该段落会被放到指令内部</p>
</test-transclude>
```

上面生成后的 DOM 结构为：

![transclude执行结果](http://ww1.sinaimg.cn/large/765147e8gy1fcr78qgt0wj20c203hjre)

## `restrict(String)`

指令的使用形式。

值可以为：

* `'E'` - 指令作为元素使用
* `'A'` - 指令作为属性使用
* `'C'` - 指令作为类名使用
* `'M'` - 指令作为注释使用（不常用）

可以是以上值的组合，如 `restrict: 'EA'` 表示指令既可以作为属性使用，也可以作为元素使用。

## `scope(Boolean or Object)`

关于 scope 选项将会在后面的指令 scope 中细说。

## `controller(Function)`

一般情况下不需要使用指令的 `controller`，只要使用 `link` 就够了，后面会细说 link 函数。

用 `controller` 的场景是该指令（a）会被其他指令（b）`require` 的时候，在 b 的指令里可以传入 a 的这个 controller，目的是为了指令间的复用和交流。而 `link` 只能在指令内部中定义行为，无法做到这样。

## `controllerAs(String)`

为控制器指定别名，这样可以在需要控制器的地方使用该名字进行注入。

## `require(String or Array)`

表示指令依赖于一个或多个指令，并注入所依赖指令的控制器到 `link` 函数的第四个参数中。如果所依赖的指令不存在，或所依赖指令的控制器不存在则会报错。

依赖名称前缀可以为：

* (没有前缀) - 在当前元素中查找依赖指令的控制器，如果不存在则报错。
* `?` - 在当前元素中查找依赖指令的控制器，如果不存在传 `null` 到 `link` 中。
* `^` - 在当前元素及父元素中查找依赖指令的控制器，如果不存在则报错。
* `?^` -  在当前元素及父元素中查找依赖指令的控制器，如果不存在传 `null` 到 `link` 中。

例子：

```JavaScript
app.directive('validate', [
	function () {
		return {
			restrict: 'A',
			require: 'ngModel',
			link: function (scope, ele, attrs, ngModelCtrl) {
				// 监听值变化
				ngModelCtrl.$viewChangeListeners.push(function () {
					scope.validateResult = ngModelCtrl.$viewValue === 'Heron';
				});
			}
		};
	}
]);

app.controller('myCtrl', [
	'$scope',
	'$cookieStore',
	function ($scope, $cookieStore) {
		$scope.name = 'Heron';

		$scope.sayHi = function (name, age) {
			alert('Hello ' + name + ', your age is ' + age);
		}
	}
]);
```

```HTML
<div ng-controller="myCtrl">
	<input type="text" ng-model="name" validate>
	<p>
		validate 结果：{{validateResult}}
	</p>
</div>
```

运行结果如图：

![require运行结果](http://ww1.sinaimg.cn/large/765147e8gy1fcradk4yflg208602rq2r)

## `compile(Function)` 和 `link(Function)`

创建的创建过程可以分为编译(compile)阶段和链接(link)阶段，因此两者放一起讲。

两者区别在于：

* `compile` 函数的作用是对指令的模板进行转换。

* `link` 函数的作用是在视图和模型之间建立关联，包括注册事件监听函数和更新 `DOM` 操作。

* `scope` 在链接阶段才会被绑定到元素上，因此 `compile` 函数中没有入参 `scope`。

* 对于同一个指令的多个示例，`compile` 函数只会执行一次，而 `link` 函数在每个实例中都会执行。

* 如果自定义了 `compile` 函数，则自定义的 `link` 函数 无效，而是使用 `compile` 函数 返回的 `link` 函数。

# 指令 scope

scope 选项有三种值：

* `false` - 使用父 `scope`。改变父 `scope` 会影响指令 `scope`，反之亦然。

* `true` - 继承父 `scope`，并创建自己的 `scope`。改变父 `scope` 会影响指令 `scope`，而改变指令 `scope` 不会影响父 `scope`。

* `{}` - 不继承父 `scope`，创建独立的 `scope`。如果不使用双向绑定策略(后面会讲)，改变父 `scope` 不会影响指令 `scope`，反之亦然。

例子：

```JavaScript
app.controller('myCtrl', [
	'$scope',
	'$cookieStore',
	function ($scope, $cookieStore) {
		$scope.scopeFalse = 'Heron';
		$scope.scopeTrue = 'Heron';
		$scope.scopeObject = 'Heron';
	}
]);
 
app.directive('directiveFalse', [
	function () {
		return {
			restrict: 'EA',
			scope: false,
			template: 
				'<div>\
					<p>\
						<span>指令 scope: </span>\
						<input type="text" ng-model="scopeFalse">\
					</p>\
				</div>'
		};
	}
]);
app.directive('directiveTrue', [
	function () {
		return {
			restrict: 'EA',
			scope: true,
			template: 
				'<div>\
					<p>\
						<span>指令 scope: </span>\
						<input type="text" ng-model="scopeTrue">\
					</p>\
				</div>'
		};
	}
]);
app.directive('directiveObject', [
	function () {
		return {
			restrict: 'EA',
			scope: {},
			template: 
				'<div>\
					<p>\
						<span>指令 scope: </span>\
						<input type="text" ng-model="scopeObject">\
					</p>\
				</div>',
			link: function (scope) {
				// 由于使用独立scope，因此需要自己定义变量
				scope.scopeObject = 'Heron';
			}
		};
	}
]);
```

```HTML
<div ng-controller="myCtrl">
	<h3>scope: false</h3>
	<p>
		<span>父 scope: </span>
		<input type="text" ng-model="scopeFalse">
	</p>
	<directive-false></directive-false>
	<h3>scope: true</h3>
	<p>
		<span>父 scope: </span>
		<input type="text" ng-model="scopeTrue">
	</p>
	<directive-true></directive-true>
	<h3>scope: {}</h3>
	<p>
		<span>父 scope: </span>
		<input type="text" ng-model="scopeObject">
	</p>
	<directive-object></directive-object>
</div>
```

运行结果如图：

![指令scope运行结果](http://ww1.sinaimg.cn/large/765147e8gy1fcs2qh3vogg20860a074e)

针对独立 scope，可以通过在对象中声明如何从外部传入参数。有以下三种绑定策略：

* `@` - 使用 DOM 属性值单项绑定到指令 `scope` 中。此时绑定的值总是一个字符串，因为 `DOM` 的属性值是一个字符串。

	```
	<div my-directive age="26"></div>

	scope: {
	    age: '@'
	}
	```

* `=` - 在父 `scope` 和指令 `scope` 之间建立双向绑定。

	```
	<div my-directive age="age"></div>

	scope: {
	    age: '='
	}
	```

* `&` - 使用父 `scope` 的上下文执行函数。一般用于绑定函数。

	```
	<div my-directive sayHi="sayHi()"></div>

	scope: {
	    sayHi: '&'
	}
	```

绑定函数时，有时需要向指令外部传递参数，如下：

```JavaScript
app.controller('myCtrl', [
	'$scope',
	'$cookieStore',
	function ($scope, $cookieStore) {
		$scope.name = 'Heron';

		$scope.sayHi = function (name, age) {
			alert('Hello ' + name + ', your age is ' + age);
		};
	}
]);

app.directive('myDirective', [
	function () {
		return {
			restrict: 'E',
			replace: true,
			scope: {
				clickMe: '&'
			},
			template: 
				'<div>\
					<button class="btn btn-info" ng-click="clickMe({ age: age })">点我</button>\
				</div>',
			link: function (scope) {
				scope.age = 26;
			}
		};
	}
]);
```

```HTML
<div ng-controller="myCtrl">
	<my-directive click-me="sayHi(name, age)"></my-directive>
</div>
```

运行结果如图：

![指令向外部传递参数](http://ww1.sinaimg.cn/large/765147e8gy1fcs4mcf9hfg211r09vzki)

说明一下：首先声明 `clickMe: '&'` 使用父 scope 的环境执行 clickMe 函数，然后在传递给指令时声明 `click-me="sayHi(name, age)"`，表示父 scope 的 `sayHi` 方法需要两个参数，一个是 name，一个是 age，然后再指令中使用对象 {} 的方式向外传递参数，如 ` ng-click="clickMe({ age: age })"`，表示向指令外传递 age 参数，sayHi 方法从指令拿到 age 参数，再从自己的上下文中拿到 name 参数。

# 结语

AngularJS 指令的开发和使用千变万化，也有许多坑，希望大家留意，也希望大家能在评论区多多交流心得。