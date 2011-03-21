<?
    // no direct access
    defined('_JEXEC') or die;

    jimport('joomla.application.component.controllerform');
    jimport('joomla.user.user');
    jimport('joomla.access.access');

    class LrgalleryControllerService extends JControllerForm
    {
        /*
         * ID группы администраторов
         */
        const adminGroupID = 7;
        
        /*
         * Вход в систему
         * Используются имя пользователя и пароль пользователя из группы администраторов
         */
        public function login($username, $password)
        {
            // Пытаемся найти указанного пользователя
            $user =& JFactory::getUser($username);            
            if ($user == null)
                return false;
            
            // Если пользователь есть, проверяем, входит ли он в административную группу
            $acl =& JFactory::getACL();
            $userGroups = JAccess::getGroupsByUser($user->getParam('id'));
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
            
            // Если всё в порядке, сгенерируем новый токен, внесём в базу и вернём его
            $token = md5(date());
        }
        
        public function createUser($username, $password, $folderName)
        {
            
        }
        
        public function uploadPhoto($userName, $photoName, $fileName)
        {
                        
        }
        
        public function getPhotoInfo($photoId)
        {
            
        }
        
        public function getPhotoInfo($userName, $photoName)
        {
            
        }
        
        public function deletePhoto($photoId)
        {
            
        }
        
        public function deletePhoto($userName, $photoName)
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