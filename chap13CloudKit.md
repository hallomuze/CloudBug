.
# Day 13 :: CloudKit Web Services

CloudKit JS 는 WWDC 15에 소개되었고, 이는 개발자들이 web interface를 이용하여 user들은 기존 CloudKit app의 것과 동일한 Container를 사용할 수 있게끔하는 것이다. CloudKit의 주된 제약중에 하나는 iOS와 OS X 에서만 사용가능했던(access) 것이다.  이 제약점을 이번에 제거함으로써 더욱더 많은 App 개발자들이 CloudKit을 사용하기를 바란다.

이번 포스트에서는, CloudKit JS 의 기능을 볼 것이며 샘플 노트 App을 만들 것이다. App을 사용해서 user들은 중요한 노트들을 cloud에 저장하게 해 줄 것이다. 

## CloudKit JS

CloudKit JS 는 아래 브라우저들을 지원한다:

- Safari
- Firefox
- Chrome
- IE
- Edge

흥미롭게도, node역시 지원하는데 이는 여러분의 자체 middle tier 서버로부터의 request를 실행하고 이를 여러분의 API로 포워드 할 수 있게 해 준다.

### CloudKit JS Application 만들기

CloudKit JS의 기능을 보여줄 데모앱을 사용하면 공유노트(shared notes)를 CloudKit에 저장할수 있다.

![완성된 첫 web application](images/CloudNotes.png)

자 이제 어떻게 이 app이 만들어 졌는지 하나씩 보자. CloudKit앱을 만들때 첫 걸음은 iCloud developer dashboard를 open하는 것이다(iOS 나 JS나 동일). 이 과정을 통해서 여러분들은 앱의 상세사항을 변경할 수 있고, record type설정, security roles설정, 데이터입력, 또 기타등등을 할 수 있다. 참고내용은여기서 찾아보자  [https://icloud.developer.apple.com/dashboard](https://icloud.developer.apple.com/dashboard).

새App의 이름은 CloudNotes이다. 우선 모든세팅은 default로 두자.

App이 Setup 된 후, 새로운 record type를 지정해야 한다. 이 App은 제목과 내용을 포함한 간단한 note를 저장한다. 좌측의 'Schema' 아래 'Record Types'옵션을 선택하자. 'Users'record type은 이미 존재해 있을 것이다. 이는 기본적으로 생성된다.

add를 클릭하고 'CloudNote'라는 이름으로 new record type 를 생성하자. 이 레코드를 사용해서 데이터를 저장할 예정이다.

![Creating a CloudNote record type](images/cloudNote.png)

그리고 나서 CloudsNote record의 필드에 title , content를 추가하자.(둘다 Strings타입)

다음, 데이터를 읽어오고 웹페이지에 표시할만한 record를 생성하자. 좌측메뉴의 "Public Data"섹션 - "Default Zone"를 선택하자. 만들 앱의 모든 데이터는 public 타입이다. 상용 앱에서는 private zone에 데이터를 저장하고 싶을테지만 이번 tutorial에서는 보안,권한등은 생략하고 심플하게 제작하겠다.
![CloudNote instance 만들기](images/createNote.png)

add를 클릭하시면 title과 content를 넣을 수 있는 옵션이 주어질 것이다. 이후 save를 클릭하면 새노트 데이터는 CloudKit에 저장될것이다.(persisted into)

이제 CloudKit instance 에 데이터를 만들었다. 이제 javascript를 이용하고 표시해보자.

#### JS App 구조 

만들 앱은 딱 한페이지만(index.html) 가질예정이다, 이 파일은 외부 JavaScript파일을 사용하여 CloudKit로 부터 데이터를 요청하거나 저장할 것이다. data 가 잘 표시되게 하기 위해서, [Knockout JS](http://knockoutjs.com/)를 사용할 것이다. Knockout은 UI와 CloudKit에서 가져온 data set사이의 binding 을 선언함으로써 작업을 심플하게 해 줄 것이다. 이렇게 함으로써 data model에 변경이 있는 경우 UI가 자동으로 refresh 되게 해줄 것이다. 또한 별도의 CSS 를 작성하지않고, bootstrap으로 부터 style 을 import 할 것이다. 

아래에 imports에 대한 결과 및  CloudKit import 부분이다.

	<html>
	<head>
		<title>iOS9 Day by Day - CloudKit Web Services Example</title>
		<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
		<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/knockout/3.3.0/knockout-min.js"></script>
		<script type="text/javascript" src="cloudNotes.js"></script>
		<script src="https://cdn.apple-cloudkit.com/ck/1/cloudkit.js" async></script>
	</head>

`cloudNotes.js`내용을 보자 그리고 어떻게 우리가 CloudKit로 부터 data를 요청할 수 있는지 보자.

data 를 요청하기에 앞서, 반드시 CloudKit API 이 로딩할 시간을 주어야 한다. 따라서 해당 내용을 window eventListener 에 코딩하겠다. 이 코드는 'cloudkitloaded'이벤트를 모니터링한다(listens)

	window.addEventListener('cloudkitloaded', function() {

CloudKit가 일단 로딩된 후 identifier, 환경설정, API Token등을 이용하여 세팅 할 필요가 있다.

		CloudKit.configure({
			containers: [{
				containerIdentifier: 'iCloud.com.shinobicontrols.CloudNotes',
				apiToken: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
				environment: 'development'
			}]
		});

API token를 생성하기 위해서는 다시 CloudKit Dashboard 로 가자. 'Admin' 에서 'API Tokens' 를 선택하고 add를 클릭하자. API token 의 이름을 정하고 위의 코드(configuration code) 상에 copy and paste하자.

![API Token Setup](images/apiTokenSetup.png)

`cloudNotes.js`버전은 [Knockout JS](http://knockoutjs.com/) 를 사용하는데, 이는 model을 HTML과 합치기(bind) 위함이다. Page 관리를 위해서 `CloudNotesViewModel` 를 생성하였다. 이 모델은 모든 노트에 있는 array 를 포함하고 있으며, 새로운 노트 저장을 위한 function, 서버로 부터 notes 를 가져오거나,  인증상태표시 및 비 인증상태를 표시해준다.(authenticated and unauthenticated state)

View Model 이 이러한 function 을 호출하기에 앞서 반드시 CloudKit 인증을 셋업해야 한다.

	container.setUpAuth().then(function(userInfo) {
		// Either a sign-in or a sign-out button will be added to the DOM here.
		if(userInfo) {
			self.gotoAuthenticatedState(userInfo);
		} else {
			self.gotoUnauthenticatedState();
		}
		self.fetchRecords(); // Records are public so we can fetch them regardless.
	});

Promise 가 resolved 되면 sign-in 또는 sign-out 버튼이 DOM에 추가될 것이다.(이는 유저의 login 상태에 따름) . 따라서 여러분은 div와함께 페이지상에 "apple-sign-in-button" id 를 가져야 한다. 이 `container.setUpAuth()` 함수호출은 div 가 적절한 sign in 버튼을 포함하도록 자동적으로 수정한다.

#### Fetching Records

fetch records 함수는 'CloudNote'타입으로된 모든 레코드를 query 한다. (해석체크 ???)

	self.fetchRecords = function() {
		var query = { recordType: 'CloudNote' };

		// Execute the query.
		return publicDB.performQuery(query).then(function (response) {
			if(response.hasErrors) {
				console.error(response.errors[0]);
				return;
			}
			var records = response.records;
			var numberOfRecords = records.length;
			if (numberOfRecords === 0) {
				console.error('No matching items');
				return;
			}

			self.notes(records);
		});
	};

위에서 여러분은 어떻게 recordType에 기초한 basic query 가 셋업되는지 , 또 public database 위에서 실행하는 것을 볼 수 있다. public database 에서는 Query 가 실행될 필요는 없다, 또한 private database 에서는 실행될 수 있다. 다만 현재 app 에서 모든 작업은 public 이다.

노트가 fetch 된 이후, self.notes 로 저장한다(이는 knockout observable 임). 무슨 말이냐면 note template을 이용해 HTML 이 만들어진다는 의미이며 , 또 fetch된 노트가 페이지에 나타난다는 뜻이다.

	<div data-bind="foreach: notes">
		<div class="panel panel-default">
			<div class="panel-body">
				<h4><span data-bind="text: fields.title.value"></span></h4>
				<p><span data-bind="text: fields.content.value"></span></p>
			</div>
		</div>
	</div>

위 템플릿은 foreach binding 을 이용하여 `notes` 를 반복수행(iterates)한다, 그리고 각 노트의 `fields.title.value` 와 `fields.content.value` 값을 패널에 프린트한다.

![A rendered node in the HTML](images/renderedNote.png)

User 가 sign in 한 이후, User들은 'Add New Note' 패널을 볼 수 있을 것이다. 따라서 `saveNewNote` 함수는 CloudKit 에 새 레코드를 저장할 수 있어야 한다.

	if (self.newNoteTitle().length > 0 && self.newNoteContent().length > 0) {
		self.saveButtonEnabled(false);

		var record = {
			recordType: "CloudNote",
			fields: {
				title: {
					value: self.newNoteTitle()
				},
				content: {
					value: self.newNoteContent()
				}
			}
		};

함수의 시작부분을 보면, record 가 올바른지 체크하는 기본 validation 을 수행하고, 그리고 현재 form 에있는 data에 근거해서 새로운 record 를 생성한다.

일단 new record 가 셋업이 되면, CloudKit에 저장할 준비가 된 것이다. 

	publicDB.saveRecord(record).then(
		function(response) {
			if (response.hasErrors) {
				console.error(response.errors[0]);
				self.saveButtonEnabled(true);
				return;
			}
			var createdRecord = response.records[0];
			self.notes.push(createdRecord);

			self.newNoteTitle("");
			self.newNoteContent("");
			self.saveButtonEnabled(true);
		}
	);

`publicDB.saveRecord(record)`라인은 public database 에 새로 생성된 레코드를 저장하고 이에대한 promise를 리턴한다. 생성된 레코드는 기존의 레코드에 속한 array로 push되어 매번 refetch할 필요성을 없애준다, 그런이후 form 이 clear되고 save버튼이 다시 활성화(enable) 된다.

### iOS App

CloudKit 를 이용하여 어떻게 Data 가 공유 되는지 보여주기 위해서 이 블로그포스트에 iOS app 소스 역시 포함되어 있다.

![Compatible iOS App Screenshot](images/iosApp1.png)

셋업을 위해 Xcode 에서 간단히 master detail application 를 만들었다.

iCloud와 잘 동작하게 만들기 위해서, Xcode file탐색기의 프로젝트를 선택후 target - capabilities 를 선택하기 바란다. 거기 iCloud 를 on 으로 선택하자. 스위치를 click 하면 Xcode 가 개발자센터와 통신을해서 여러분의 App 에 필요한 entitlements 를 추가할 것이다.

Configuration panel 은 이제 아래처럼 보일 것이다.

![XCode configuration setup](images/xcodeSetup.png)

여러분들은 이제 CloudKit 를 사용할 준비가 되었다. 더이상 자세한 내용을 설명하지는 않겠다. 왜냐면 이미  [comprehensive explanation of how to use CloudKit on iOS in iOS8-day-by-day](https://www.shinobicontrols.com/blog/ios8-day-by-day-day-33-cloudkit) 가 준비되어 있기 때문이다, 다만 우선 이 강좌를 보면 note를 선택할 때 app이 어떤식으로 작동하는지 알 수 있다. title 은  view controller title 이 되고, 내용(contents)는 화면 중앙에 표시되어야 한다.

![Compatible iOS App Screenshot](images/iosApp2.png)

## Conclusion

자 여기까지 CloudKit JS API가 얼마나 사용하기 심플한지 잘 보셨으리라 생각한다. 저자는 애플이 web기반의 CloudKit 을 제공해서 기쁘다, 하지만 개인적으로 아직 내가 app 개발시 사용하기에는 개선의 여지가 있다고 본다.

이미 시장에는 넘쳐나는 서드파티 cloud 서비스들이 더 많은 기능과 세련된 문서화로 출시되고 있고, 타 플랫폼을 위한 네이티브 SDK들도 제공된다. 수차례 시도해보았지만 시뮬레이터에서 작동하는 CloudKit 서비스는 아직까지 보지 못 했다. 이른 시간 내에 이 사항이 개선되지 않는다면 개발시 또 다른 장벽이 될 것으로 보인다.

확실히 CloudKit 를 사용할 경우가 발생할 것이기 때문에 모두들 한번씩 시도해 볼 것을 권한다. 장래에 또 다른 플랫폼에서 데이터를 access할 필요가 발생할 것이라면 고려해 보시기 바란다.

## Further Reading
앞서 나온 CloudKit JS 와 Web Services 에 관한 자세한 정보는 WWDC session 710 를 보기바란다 , [CloudKit JS and Web Services](https://developer.apple.com/videos/wwdc/2015/?id=608). 우리가 여기서 만들어본 프로젝트는 [GitHub](https://github.com/shinobicontrols/iOS9-day-by-day/tree/master/13-CloudKit-Web-Services)에서 볼 수 있음을 잊지말자.

질문이나과 피드백이 있으시면 환영한다. iOS9 Day-by-Day series에 대한 최신뉴스 및 업데이트가 필요하면 tweet [@christhegrant](http://twitter.com/christhegrant) 로 주시거나 또는  [@shinobicontrols](http://twitter.com/shinobicontrols) 를 팔로우하면 된다. 읽어주셔서 감사합니다!
