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
         * ID группы администраторов
         */
        const adminGroupID = 7;
        
        /*
         * ID группы пользователей галереи
         */
        const userGroupID = 4;
        
        /*
         * Директория с папками пользователей
         */
        const userFolders = "media/user_folders";
        
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
            $token = md5(date('diu'));            
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
            if ($expireDate === false)
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
            echo $this->createUSer($username, $password, $folderName);
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
            $folderToCreate = self::userFolders . "/$folderName";                        
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
            $userName = JRequest::getString('userName');
            $photoName = JRequest::getString('photoName');
            $fileName = JRequest::getString('fileName');
            $token = JRequest::getString('token');
            echo $this->uploadPhoto($userName, $photoName, $fileName, $token);
        }
        
        /*
         * Загрузка фотографии в папку пользователя
         */
        public function uploadPhoto($userName, $photoName, $fileName, $token)
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
            if ($folderName === false)
                return JError::raiseWarning(3, "Error while retrieving user folder from database", 
                    $db->stderr());
            
            $path = self::userFolders . "/$folderName";
            if (!JFolder::exists($path))
                return JError::raiseWarning(4, "User folder doesn't exist");
            
            // Переместим туда фотографию
            $baseName = JFile::getName($fileName);
            $destPath = "$path/$baseName";
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
            
            return true;
        }
        
        public function getPhotoInfo($photoId, $token)
        {
            
        }        
        
        public function deletePhoto($photoId, $token)
        {
            
        }       
        
        public function deleteUser($userName, $token)
        {
            
        }
        
        public function logout($token)
        {
            
        }
    }
?>    