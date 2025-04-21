// web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyABQMQbVyGy-ei8wr0Al7GBmNmCFM58ZOY",
  authDomain: "kita-tongtong.firebaseapp.com",
  projectId: "kita-tongtong",
  storageBucket: "kita-tongtong.appspot.com",
  messagingSenderId: "531192957050",
  appId: "1:531192957050:web:5689e3ca8ddaa8199593c3"
});

const messaging = firebase.messaging();
