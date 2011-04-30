<?
    // no direct access
    defined('_JEXEC') or die;

    jimport('joomla.application.component.controllerform');
    jimport('joomla.user.user');
    jimport('joomla.access.access');
    jimport('joomla.filesystem.folder');
    jimport('joomla.filesystem.file');

    class LrgalleryControllerService extends JControllerForm
    {
        /*
         * Директория с папками пользователей
         */
        var $userFolders;
        
        /*
         * ID группы администраторов
         */
        const adminGroupID = 7;
        
        /*
         * ID группы пользователей галереи
         */
        const userGroupID = 4;                
        
        public function __construct($config = array()) {
            parent::__construct($config);
            $this->userFolders = JPATH_SITE . DS . "media". DS . "user_folders";
        }
        
        public function loginTest()
        {
            $username = JRequest::getString('username');
            $password = JRequest::getString('password');
            echo $this->login($username, $password);
        }
        
        /*
         * Вход в систему
         * Используются имя пользователя и пароль пользователя из группы администраторов
         */
        public function login($username, $password)
        {
            
            // Пытаемся найти указанного пользователя
            $user = &JFactory::getUser($username);            
            if (empty($user))
                return JError::raiseWarning(1, "Requested user doesn't exist");
            
            // Если пользователь есть, проверяем, входит ли он в административную группу
            $acl = &JFactory::getACL();
            $userId = $user->id;
            $userGroups = JAccess::getGroupsByUser($userId);
            if (!in_array(self::adminGroupID, $userGroups))
                return JError::raiseWarning(2, "User is not in administrative group", $userGroups);
            
            // Если пользователь входит в группу администраторов, пробуем аутентифицировать его            
            $credentials = array();
            $credentials['username'] = $username;
            $credentials['password'] = $password;
            $app = JFactory::getApplication();
            $error = $app->login($credentials);
            if (JError::isError($error))
                return $error;
            
            // Почистим таблицу токенов от устаревших записей
            $db =& JFactory::getDBO();
            $db->setQuery("DELETE FROM #__lrgallery_tokens WHERE expire_date < now()");
            if (!$db->query())
                return JError::raiseWarning(3, "Error occured while clearing old tokens", $db->stderr());
            
            // Если всё в порядке, сгенерируем новый токен, внесём в базу и вернём его
            $token = md5(uniqid(rand(),1));            
            $db->setQuery("INSERT INTO #__lrgallery_tokens
                                (token, user_id, start_date, expire_date)
                           VALUES
                                ('$token', $userId, now(), date_add(now(), interval 4 hour))");
            if (!$db->query())
                return JError::raiseWarning(3, "Error occured while inserting a new token", $db->stderr());
            
            return $token;
        }
        
        public function checkLoginTest()
        {
            $token = JRequest::getString('token');
            echo $this->checkLogin($token);
        }
        
        /*
         * Проверка валидности токена
         */
        private function checkLogin($token)
        {
            $db = &JFactory::getDBO();
            $tokenQ = $db->quote($token);
            $db->setQuery("SELECT expire_date
                             FROM #__lrgallery_tokens
                            WHERE token = $tokenQ");
            $expireDate = $db->loadResult();
            if (empty($expireDate))
                return JError::raiseWarning(1, "Error occured while checking token from database", 
                    $db->stderr());
            else if (empty($expireDate))
                return JError::raiseWarning(2, "Specified token doesn't exist");
            else if (strtotime($expireDate) < strtotime(date("Y-m-d h:m:s")))
                return JError::raiseWarning(3, "Specified token is expired");
            else 
                return true;
        }
        
        public function createUserTest()
        {
            $username = JRequest::getString('username');
            $password = JRequest::getString('password');
            $folderName = JRequest::getString('folderName');
            $token = JRequest::getString('token');
            echo $this->createUSer($username, $password, $folderName, $token);
        }

        /*
         * Создание нового пользователя галереи
         */
        public function createUser($username, $password, $folderName, $token)
        {
            $err = $this->checkLogin($token);
            if (JError::isError($err))
                return JError::raiseWarning(1, "You are not logged in : " . $err);
            
            if (empty($username))
                return JError::raiseWarning(1, "No username specified");
            
            // Проверим, нет ли уже такого пользователя
            $user = &JFactory::getUser($username);
            if (!empty($user))
                return JError::raiseWarning(2, "Specified user already exists", $user);
            
            // Создадим нового пользователя
            $instance = JUser::getInstance();
            $instance->set('id', 0);
            $instance->set('name', $username);
            $instance->set('username', $username);
            
            $salt  = JUserHelper::genRandomPassword(32);
            $crypt = JUserHelper::getCryptedPassword($password, $salt);                                    
            $instance->set('password', "$crypt:$salt");
            
            $instance->set('email', "$username@softlit.ru");
            $instance->set('usertype', 'deprecated');
            $instance->set('groups', array(self::userGroupID));                        
            $result = $instance->save();
            if (!$result)   
                return JError::raiseWarning(3, "Error occured while saving a new user", $instance->getError());
            
            // Создадим папку пользователя
            // Если такая папка уже существует - удалим все файлы из неё
            if (empty($folderName)) {
                $folderName = $username;
            }
            $folderToCreate = $this->userFolders . DS . $folderName;                        
            if (JFolder::exists($folderToCreate)) {
                foreach (JFolder::files($folderToCreate, '*', true, true) as $file) {
                    JFile::delete($file);
                }
                $db = &JFactory::getDBO();
                $folderNameQ = $db->quote($folderName);
                $db->setQuery("DELETE 
                                 FROM #__lrgallery_userfolders
                                WHERE folder_name = $folderNameQ");
                if (!$db->query())
                    return JError::raiseWarning(4, "Error occured while deleting an existing folder from database", 
                        $db->stderr());
            }
            else
                JFolder::create($folderToCreate);
            
            // Вставим запись в #__lrgallery_userfolders
            $db = &JFactory::getDBO();
            $userId = $instance->id;
            $db->setQuery("INSERT INTO #__lrgallery_userfolders
                                (user_id, folder_name)
                           VALUES
                                ($userId, $folderNameQ)");
            if (!$db->query())
                return JError::raiseWarning(5, "Error while saving user folder to database", $db->stderr());
            
            return true;
        }
        
        public function uploadPhotoTest()
        {
            $username = JRequest::getString('username');
            $photoName = JRequest::getString('photoName');
            $fileName = JRequest::getString('fileName');
            $token = JRequest::getString('token');
            echo $this->uploadPhoto($username, $photoName, $fileName, $token);
        }
        
        /*
         * Загрузка фотографии в папку пользователя
         */
        public function uploadPhoto($username, $photoName, $fileName, $token)
        {
            $err = $this->checkLogin($token);
            if (JError::isError($err))
                return JError::raiseWarning(1, "You are not logged in : " . $err);
            
            // Получим пользователя по его имени
            $user = &JFactory::getUser($username);
            if (empty($user))
                return JError::raiseWarning(2, "Requested user doesn't exist");
            
            // Получим папку пользователя
            $db = &JFactory::getDBO();
            $userId = $user->id;
            $db->setQuery("SELECT folder_name
                             FROM #__lrgallery_userfolders
                            WHERE user_id = $userId");
            $folderName = $db->loadResult();
            if (empty($folderName))
                return JError::raiseWarning(3, "Error while retrieving user folder from database", 
                    $db->stderr());
            
            $path = $this->userFolders . DS . $folderName;
            if (!JFolder::exists($path))
                return JError::raiseWarning(4, "User folder doesn't exist");
            
            // Переместим туда фотографию
            $baseName = JFile::getName($fileName);
            $destPath = $path . DS . $baseName;
            if (!JFile::move($fileName, $destPath))
                return JError::raiseWarning(5, "Error while uploading file");
            
            // Вставим запись в БД
            $photoNameQ = $db->quote($photoName);
            $baseNameQ = $db->quote($baseName);
            $db->setQuery("INSERT INTO #__lrgallery_photos
                                (name, user_id, file_name)
                           VALUES
                                ($photoNameQ, $userId, $baseNameQ)");
            if (!$db->query())
                return JError::raiseWarning(6, "Error while saving uploaded photo to database", 
                    $db->stderr());
            
            return $db->insertid();
        }
        
        public function getPhotoInfoTest()
        {
            $photoId = JRequest::getString('photoId');
            $token = JRequest::getString('token');
            var_dump($this->getPhotoInfo($photoId, $token));
        }
        
        /*
         * Получение информации о фотографии, включая метаданные
         */
        public function getPhotoInfo($photoId, $token)
        {
            $err = $this->checkLogin($token);
            if (JError::isError($err))
                return JError::raiseWarning(1, "You are not logged in : " . $err);
            
            // Получим основные данные фотографии
            $db = &JFactory::getDBO();
            $photoIdQ = $db->quote($photoId);
            $db->setQuery("SELECT p.id, 
                                  p.name, 
                                  p.file_name,
                                  u.username
                             FROM #__lrgallery_photos p,
                                  #__users u
                            WHERE p.user_id = u.id
                              AND p.id = $photoIdQ");
            $photoInfo = $db->loadObject();
            if (empty($photoInfo))
                return JError::raiseWarning(1, "Error while retrieving photo from database", 
                    $db->stderr());
            
            // Получим метаданные фотографии
            $db->setQuery("SELECT meta.name,
                                  data.value
                             FROM #__lrgallery_meta meta,
                                  #__lrgallery_metadata data
                            WHERE meta.id = data.meta_id
                              AND data.photo_id = $photoIdQ");
            $metadata = $db->loadAssocList();
            if (empty($metadata))
                return JError::raiseWarning(2, "Error while retrieving photo metadata from database", 
                    $db->stderr());
            
            $photoInfo->metadata = $metadata;
            return $photoInfo;
        }
        
        public function deletePhotoTest()
        {
            $photoId = JRequest::getInt('photoId');
            $token = JRequest::getString('token');
            echo $this->deletePhoto($photoId, $token);
        }
        
        /*
         * Удаление фотографии
         */
        public function deletePhoto($photoId, $token)
        {
            $err = $this->checkLogin($token);
            if (JError::isError($err))
                return JError::raiseWarning(1, "You are not logged in : " . $err);
            
            // Удалим файл
            $db = &JFactory::getDBO();
            $photoIdQ = $db->quote($photoId);
            $db->setQuery("SELECT p.file_name, u.folder_name 
                             FROM #__lrgallery_photos p,
                                  #__lrgallery_userfolders u
                            WHERE p.user_id = u.user_id
                              AND p.id = $photoIdQ");
            $result = $db->loadObject();
            if (empty($result))
                return JError::raiseWarning(2, "Error occured while getting photo from database", 
                    $db->stderr());
            
            $fileToDelete = $this->userFolders . DS . 
                    $result->folder_name . DS . $result->file_name;
            if (JFile::exists($fileToDelete))
                JFile::delete($fileToDelete);
            
            // Удалим фото из БД                        
            $db->setQuery("DELETE 
                             FROM #__lrgallery_photos
                            WHERE id = $photoIdQ");
            if (!$db->query())
                return JError::raiseWarning(3, "Error occured while deleting photo from database", 
                    $db->stderr());
            
            return true;
        }       
        
        public function deleteUserTest()
        {
            $username = JRequest::getString('username');
            $token = JRequest::getString('token');
            echo $this->deleteUser($username, $token);
        }
        
        /*
         * Удаление пользователя
         */
        public function deleteUser($username, $token)
        {
            $err = $this->checkLogin($token);
            if (JError::isError($err))
                return JError::raiseWarning(1, "You are not logged in : " . $err);
            
            // Проверим, есть ли такой пользователь
            if (empty($username))
                return JError::raiseWarning(2, "No username specified");
            $user = &JFactory::getUser($username);
            if (empty($user))
                return JError::raiseWarning(3, "Specified user does'n exist");
            
            // Удалим пользователя
            $userId = $user->id;
            if (!$user->delete())
                return JError::raiseWarning(4, "Error while deleting user from database");
            
            // Получим его папку
            $db = &JFactory::getDBO();
            $db->setQuery("SELECT folder_name
                             FROM #__lrgallery_userfolders
                            WHERE user_id = $userId");
            $userFolder = $db->loadResult();
            if (empty($userFolder))
                return JError::raiseWarning(5, "Error occured while getting user folder from database", 
                    $db->stderr());
            
            // Удалим его папку из файловой системы
            $folderToDelete = $this->userFolders . DS . $userFolder;
            if (JFolder::exists($folderToDelete)) {
                foreach (JFolder::files($folderToDelete, '*', true, true) as $file) {
                    JFile::delete($file);
                }
                JFolder::delete($folderToDelete);
            }
            
            // Удалим его из БД
            $db->setQuery("DELETE 
                             FROM #__lrgallery_userfolders
                            WHERE folder_name = '$userFolder';
                           DELETE
                             FROM #__lrgallery_photos
                            WHERE user_id = $userId");
            if (!$db->queryBatch())
                return JError::raiseWarning(6, "Error occured while deleting user data from database", 
                    $db->stderr());
            
            return true;
        }
        
        public function logoutTest()
        {
            $token = JRequest::getString('token');
            echo $this->logout($token);
        }
        
        /*
         * Выход из системы
         */
        public function logout($token)
        {
            $err = $this->checkLogin($token);
            if (JError::isError($err))
                return JError::raiseWarning(1, "You are not logged in : " . $err);
            
            // Удаляем токен
            $db = &JFactory::getDBO();
            $tokenQ = $db->quote($token);
            $db->setQuery("DELETE
                             FROM #__lrgallery_tokens
                            WHERE token = $tokenQ");
            if (!$db->query())
                return JError::raiseWarning(2, "Error while removing token from database", 
                    $db->stderr());
            
            return true;
        }
    }
?>    