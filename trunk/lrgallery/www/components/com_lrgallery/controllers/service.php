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
                return false;
            
            // Если пользователь есть, проверяем, входит ли он в административную группу
            $acl = &JFactory::getACL();
            $userId = $user->id;
            $userGroups = JAccess::getGroupsByUser($userId);
            if (!in_array(self::adminGroupID, $userGroups))
                return false;
            
            // Если пользователь входит в группу администраторов, пробуем аутентифицировать его            
            $credentials = array();
            $credentials['username'] = $username;
            $credentials['password'] = $password;
            $app = JFactory::getApplication();
            $error = $app->login($credentials);
            if (JError::isError($error))
                return false;
            
            // Почистим таблицу токенов от устаревших записей
            $db->setQuery("DELETE FROM #__lrgallery_tokens WHERE expire_date < now()");
            if (!$db->query())
                return false;
            
            // Если всё в порядке, сгенерируем новый токен, внесём в базу и вернём его
            $token = md5(date('diu'));
            $db =& JFactory::getDBO();
            $db->setQuery("INSERT INTO #__lrgallery_tokens
                                (token, user_id, start_date, expire_date)
                           VALUES
                                ('$token', $userId, now(), date_add(now(), interval 4 hour))");
            if (!$db->query())
                return false;
            
            return $token;
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
        public function createUser($username, $password, $folderName)
        {
            if (empty($username))
                return false;
            
            // Проверим, нет ли уже такого пользователя
            $user = &JFactory::getUser($username);            
            if (!empty($user))
                return false;
            
            // Создадим нового пользователя            
            $instance = JUser::getInstance();            
            $instance->set('id', 0);
            $instance->set('name', $username);
            $instance->set('username', $username);
            $instance->set('password_clear', $password);
            $instance->set('email', "$username@softlit.ru");
            $instance->set('usertype', 'deprecated');
            $instance->set('groups', array(self::userGroupID));                        
            $result = $instance->save();
            if (!$result)   
                return false;
            
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
            }
            else
                JFolder::create($folderToCreate);
            
            // Вставим запись в #__lrgallery_userfolders
            $db = &JFactory::getDBO();
            $userId = $instance->id;
            $db->setQuery("INSERT INTO #__lrgallery_userfolders
                                (user_id, folder_name)
                           VALUES
                                ($userId, '$folderName')");
            if (!$db->query())
                return false;
            
            return true;
        }
        
        public function uploadPhoto($userName, $photoName, $fileName)
        {
                        
        }
        
        public function getPhotoInfo($photoId)
        {
            
        }        
        
        public function deletePhoto($photoId)
        {
            
        }       
        
        public function deleteUser($userName)
        {
            
        }
        
        public function logout()
        {
            
        }
    }
?>    