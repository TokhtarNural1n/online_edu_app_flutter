const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

/**
 * Эта функция запускается при создании нового документа в коллекции 'news'
 * и отправляет уведомление всем пользователям, подписанным на топик 'news'.
 */
exports.sendNewNewsNotification = functions.firestore
    .document("news/{newsId}")
    .onCreate(async (snapshot, context) => {
      const newsData = snapshot.data();

      const payload = {
        notification: {
          title: "Жаңа жаңалық!", // Заголовок уведомления
          body: newsData.title,    // В теле будет заголовок новости
          sound: "default",
        },
        data: {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "newsId": context.params.newsId, // ID для перехода на нужный экран
        },
      };

      // Отправляем уведомление в топик 'news'
      try {
        await admin.messaging().sendToTopic("news", payload);
        console.log("Уведомление о новости успешно отправлено:", newsData.title);
      } catch (error) {
        console.error("Ошибка при отправке уведомления о новости:", error);
      }
    });


/**
 * Эта функция запускается при создании нового комментария.
 * Если это ответ, она отправляет уведомление автору родительского комментария.
 */
exports.sendCommentReplyNotification = functions.firestore
    .document("news/{newsId}/comments/{commentId}")
    .onCreate(async (snapshot, context) => {
      const newComment = snapshot.data();

      // 1. Проверяем, является ли комментарий ответом (есть ли parentId)
      if (!newComment.parentId) {
        console.log("Это не ответ, уведомление не отправляем.");
        return null;
      }
      
      // 2. Получаем ID автора родительского комментария
      const parentCommentRef = db
          .collection("news").doc(context.params.newsId)
          .collection("comments").doc(newComment.parentId);
          
      const parentCommentDoc = await parentCommentRef.get();
      if (!parentCommentDoc.exists) {
          console.log("Родительский комментарий не найден.");
          return null;
      }
      const parentUserId = parentCommentDoc.data().userId;

      // 3. Предотвращаем отправку уведомления самому себе
      if (newComment.userId === parentUserId) {
        console.log("Пользователь ответил сам себе, уведомление не отправляем.");
        return null;
      }

      // 4. Получаем токен(ы) пользователя, которому отвечают
      const userTokensSnapshot = await db
          .collection("users").doc(parentUserId)
          .collection("fcm_tokens").get();

      if (userTokensSnapshot.empty) {
        console.log("У пользователя, которому отвечают, нет токенов.");
        return null;
      }

      const tokens = userTokensSnapshot.docs.map((doc) => doc.id);

      // 5. Создаем и отправляем персональное уведомление
      const payload = {
        notification: {
          title: `Вам ответил ${newComment.userName}!`,
          body: newComment.commentText,
          sound: "default",
        },
        data: {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "newsId": context.params.newsId,
        },
      };

      console.log(`Отправляем уведомление об ответе пользователю ${parentUserId}`);
      return admin.messaging().sendToDevice(tokens, payload);
    });
    exports.updateCourseModuleCount = functions.firestore
    .document("courses/{courseId}/modules/{moduleId}")
    .onWrite(async (change, context) => {
      const courseId = context.params.courseId;
      const courseRef = db.collection("courses").doc(courseId);

      // Получаем все модули для этого курса
      const modulesSnapshot = await courseRef.collection("modules").get();
      const moduleCount = modulesSnapshot.size;

      console.log(`Updating course ${courseId} with moduleCount: ${moduleCount}`);
      return courseRef.update({ moduleCount: moduleCount });
    });

/**
 * Эта функция обновляет счетчик УРОКОВ в документе курса
 * при создании или удалении урока/теста.
 */
exports.updateCourseLessonCount = functions.firestore
    .document("courses/{courseId}/modules/{moduleId}/contentItems/{contentId}")
    .onWrite(async (change, context) => {
      const courseId = context.params.courseId;
      const courseRef = db.collection("courses").doc(courseId);

      // Получаем все модули курса
      const modulesSnapshot = await courseRef.collection("modules").get();
      let totalLessons = 0;

      // Для каждого модуля считаем количество уроков и тестов
      for (const moduleDoc of modulesSnapshot.docs) {
        const contentItemsSnapshot = await moduleDoc.ref.collection("contentItems").get();
        const trackableItems = contentItemsSnapshot.docs.filter(
            (doc) => doc.data().type === "lesson" || doc.data().type === "test"
        );
        totalLessons += trackableItems.length;
      }
      
      console.log(`Updating course ${courseId} with lessonCount: ${totalLessons}`);
      return courseRef.update({ lessonCount: totalLessons });
    });