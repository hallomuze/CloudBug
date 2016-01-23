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

Next, lets create a record so that we have something to fetch and display on our webpage. Select "Default Zone" from the left hand menu, in the "Public Data" section. All of the data we are using in this application will be public. In a real application you would probably want to store data in the private zone on a per user basis, but to keep things simple we aren't addressing security and permissions in this tutorial.
다음, 데이터를 읽어오고 웹페이지에 표시할만한 record를 생성하자. 좌측메뉴의 "Public Data"섹션 - "Default Zone"를 선택하자. 만들 앱의 모든 데이터는 public 타입이다. 상용 앱에서는 private zone에 데이터를 저장하고 싶을테지만 이번 tutorial에서는 보안,권한등은 생략하고 심플하게 제작하겠다.
![CloudNote instance 만들기](images/createNote.png)

Click add and you will be given the option to enter the title and content for a new note. Then click save and your new note will be persisted into CloudKit! add를 클릭하시면 title과 content를 넣을 수 있는 옵션이 주어질 것이다. 이후 save를 클릭하면 새노트 데이터는 CloudKit에 저장될것이다.(persisted into)

Now that we have some data in our CloudKit instance, lets try and display it with some Javascript. 이제 CloudKit instance 에 데이터를 만들었다. 이제 javascript를 이용하고 표시해보자.

#### JS App 구조 

Our app is only going to have one page (index.html), which will use an external JavaScript file to request and store the data from CloudKit. In order to help display the data, we are going to be using [Knockout JS](http://knockoutjs.com/). Knockout will just simplify things for us a little bit by allowing us to declare bindings between the UI and the data set that is pulled from CloudKit. It will ensure that the UI automatically refreshes when the data model's state changes. We will also import styles from bootstrap so we don't have to write any of our own CSS. 만들 앱은 딱 한페이지만(index.html) 가질예정이다, 이 파일은 외부 JavaScript파일을 사용하여 CloudKit로 부터 데이터를 요청하거나 저장할 것이다. data 가 잘 표시되게 하기 위해서, [Knockout JS](http://knockoutjs.com/)를 사용할 것이다. Knockout은..... 

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

Before we can request any data, we must wait for the CloudKit API to load. We do this by placing our code in a window eventListener, which listens for the 'cloudkitloaded' event.
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

You'll have to go back into CloudKit Dashboard to generate an API token. You can do this by selecting 'API Tokens' from the 'Admin' area of CloudKit Dashboard, and clicking add. Give your API token a name, and copy and paste it into the configuration code seen in the code above.API token를 생성하기 위해서는 다시 CloudKit Dashboard 로 가자. 'Admin' 에서 'API Tokens' 를 선택하고 add를 클릭하자. 해석난해???

![API Token Setup](images/apiTokenSetup.png)

The code in my version of `cloudNotes.js` uses [Knockout JS](http://knockoutjs.com/) to create and bind the model to the HTML. I have created a `CloudNotesViewModel` which is responsible for managing the page. It contains an array of all of the notes, as well as functions to save a new note, fetch notes from the server, display an authenticated state and display an unauthenticated state. `cloudNotes.js`버전은 [Knockout JS](http://knockoutjs.com/) 를 사용하는데, 이는 model을 HTML과 합치기(bind) 위함이다.

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

When the promise is resolved, depending on the login state of the user, a sign-in or sign-out button will be added to the DOM. You therefore have to have a div with the id "apple-sign-in-button" on the page. This `container.setUpAuth()` function call automatically modifies this div to contain the appropriate sign in button.

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

Once the notes have been fetched, we store them into self.notes, which is a knockout observable. This means that the HTML will be regenerated using the note template, and the fetched notes should appear in the page.

	<div data-bind="foreach: notes">
		<div class="panel panel-default">
			<div class="panel-body">
				<h4><span data-bind="text: fields.title.value"></span></h4>
				<p><span data-bind="text: fields.content.value"></span></p>
			</div>
		</div>
	</div>

The template iterates through `notes` with a foreach binding, and prints each note's `fields.title.value` and `fields.content.value` values in a panel.

![A rendered node in the HTML](images/renderedNote.png)

After a user has signed in, they will see the 'Add New Note' panel. The `saveNewNote` function must therefore be able to store new records into CloudKit.

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

The line `publicDB.saveRecord(record)` saves the newly created record into the public database and returns a promise with the success of the save operation. The created record is pushed into the array of existing records so we don't need to refetch everything again, and then the form is cleared and the save button is enabled again.

### iOS App

CloudKit 를 이용하여 어떻게 Data 가 공유 되는지 보여주기 위해서 이 블로그포스트에 iOS app 소스 역시 포함되어 있다.

![Compatible iOS App Screenshot](images/iosApp1.png)

셋업을 위해 Xcode 에서 간단히 master detail application 를 만들었다.

To enable it to work with iCloud, select your project in Xcode's file explorer, select your target and then select capabilities. You should see the option to turn iCloud on. Click the switch and Xcode will communicate with the developer centre and add the entitlements required to your application.

Configuration panel 은 이제 아래처럼 보일 것이다.

![XCode configuration setup](images/xcodeSetup.png)

You're now ready to start using CloudKit in the iOS app. I won't go into the details of how it was implemented, as there's already a [comprehensive explanation of how to use CloudKit on iOS in iOS8-day-by-day](https://www.shinobicontrols.com/blog/ios8-day-by-day-day-33-cloudkit), but this is what the app should look like when you select a note. The title should be the view controller title, and the content should be displayed in the middle of the screen.

![Compatible iOS App Screenshot](images/iosApp2.png)

## Conclusion

Hopefully this post has shown how simple it is to use the CloudKit JS API. I'm glad that Apple now offer a web based API for CloudKit, but I still have some reservations and I don't think I'd personally use it if I were developing an application.

There are plenty of third party cloud service providers out there with more features and better documentation, as well as native SDKs for the other mobile platforms too. I also couldn't get any CloudKit services working on the simulator, no matter what I tried. That's certain to be another barrier to development if it's not fixed as soon as possible.

There are definitely use cases for CloudKit, and I'd encourage everyone to give it a try. Just think twice before developing an application where you will potentially need access to your data on other platforms in future.

## Further Reading
For more information on the the new CloudKit JS and Web Services features discussed in this post, take look at WWDC session 710, [CloudKit JS and Web Services](https://developer.apple.com/videos/wwdc/2015/?id=608). Don't forget, if you want to try out the projects we created and described in this post, you can find it over at [GitHub](https://github.com/shinobicontrols/iOS9-day-by-day/tree/master/13-CloudKit-Web-Services).

If you have any questions or comments then we would love to hear your feedback. Send me a tweet [@christhegrant](http://twitter.com/christhegrant) or you can follow [@shinobicontrols](http://twitter.com/shinobicontrols) to get the latest news and updates to the iOS9 Day-by-Day series. Thanks for reading!
