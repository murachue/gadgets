/*
 * FindReparse: Find reparse point(junction)
 *  by Murachue
 *
 * usage: findreparse c:\ d:\  -- find reparse point from c:\ and d:\.
 *        findreparse          -- find reparse point from current directory.
 *
 * refer: http://www.flexhex.com/docs/articles/hard-links.phtml
 */


#define _WIN32_WINNT 0x0501
#include <windows.h>
#include <winioctl.h>
#include <stdio.h>

#pragma comment (lib,"advapi32.lib")

/* --- from flexHEX page, removed "::" --- */

#define REPARSE_MOUNTPOINT_HEADER_SIZE   8

typedef struct {
  DWORD ReparseTag;
  DWORD ReparseDataLength;
  WORD Reserved;
  WORD ReparseTargetLength;
  WORD ReparseTargetMaximumLength;
  WORD Reserved1;
  WCHAR ReparseTarget[1];
} REPARSE_MOUNTPOINT_DATA_BUFFER, *PREPARSE_MOUNTPOINT_DATA_BUFFER;

// Returns directory handle or INVALID_HANDLE_VALUE if failed to open.
// To get extended error information, call GetLastError.

HANDLE OpenDirectory(LPCTSTR pszPath, BOOL bReadWrite) {
// Obtain backup/restore privilege in case we don't have it
  HANDLE hToken;
  TOKEN_PRIVILEGES tp;
  OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES, &hToken);
  LookupPrivilegeValue(NULL,
                         (bReadWrite ? SE_RESTORE_NAME : SE_BACKUP_NAME),
                         &tp.Privileges[0].Luid);
  tp.PrivilegeCount = 1;
  tp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
  AdjustTokenPrivileges(hToken, FALSE, &tp, sizeof(TOKEN_PRIVILEGES), NULL, NULL);
  CloseHandle(hToken);

// Open the directory
  DWORD dwAccess = bReadWrite ? (GENERIC_READ | GENERIC_WRITE) : GENERIC_READ;
  HANDLE hDir = CreateFile(pszPath, dwAccess, 0, NULL, OPEN_EXISTING,
                     FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS, NULL);

  return hDir;
}

#define DIR_ATTR  (FILE_ATTRIBUTE_DIRECTORY | FILE_ATTRIBUTE_REPARSE_POINT)

BOOL IsDirectoryJunction(LPCTSTR pszDir) {
  DWORD dwAttr = GetFileAttributes(pszDir);
  if (dwAttr == -1) return FALSE;  // Not exists
  if ((dwAttr & DIR_ATTR) != DIR_ATTR) return FALSE;  // Not dir or no reparse point

  HANDLE hDir = OpenDirectory(pszDir, FALSE);
  if (hDir == INVALID_HANDLE_VALUE) return FALSE;  // Failed to open directory

  BYTE buf[MAXIMUM_REPARSE_DATA_BUFFER_SIZE];
  REPARSE_MOUNTPOINT_DATA_BUFFER& ReparseBuffer = (REPARSE_MOUNTPOINT_DATA_BUFFER&)buf;
  DWORD dwRet;
  BOOL br = DeviceIoControl(hDir, FSCTL_GET_REPARSE_POINT, NULL, 0, &ReparseBuffer,
                                      MAXIMUM_REPARSE_DATA_BUFFER_SIZE, &dwRet, NULL);
  CloseHandle(hDir);
  return br ? (ReparseBuffer.ReparseTag == IO_REPARSE_TAG_MOUNT_POINT) : FALSE;
}


BOOL QueryDirectoryJunction(LPCTSTR szJunction, LPSTR szPath) {
	if (!IsDirectoryJunction(szJunction)) {
	  // Error: no junction here
	  return FALSE;
	}

	// Open for reading only (see OpenDirectory definition above)
	HANDLE hDir = OpenDirectory(szJunction, FALSE);

	BYTE buf[MAXIMUM_REPARSE_DATA_BUFFER_SIZE];  // We need a large buffer
	REPARSE_MOUNTPOINT_DATA_BUFFER& ReparseBuffer = (REPARSE_MOUNTPOINT_DATA_BUFFER&)buf;
	DWORD dwRet;

	if (DeviceIoControl(hDir, FSCTL_GET_REPARSE_POINT, NULL, 0, &ReparseBuffer,
	                                 MAXIMUM_REPARSE_DATA_BUFFER_SIZE, &dwRet, NULL)) {
	  // Success
	  CloseHandle(hDir);

	  LPCWSTR pPath = ReparseBuffer.ReparseTarget;
	  if (wcsncmp(pPath, L"\\??\\", 4) == 0) pPath += 4;  // Skip 'non-parsed' prefix
	  WideCharToMultiByte(CP_ACP, 0, pPath, -1, szPath, MAX_PATH, NULL, NULL);
	}
	else {  // Error
	  DWORD dr = GetLastError();
	  CloseHandle(hDir);
	  // Some error action (throw or MessageBox)
	  return FALSE;
	}

	return TRUE;
}

/* --- end --- */


void spc(int n)
{
	int i;

	for(i = 0; i < n; i++)
	{
		printf(" ");
	}
}

char *sspc(int n)
{
	static char buf[512];
	int i;

	for(i = 0; i < n; i++)
	{
		buf[i] = ' ';
	}
	buf[i] = '\0';

	return buf;
}

// oldway
void find_worker(int nestlv, const char *path)
{
	HANDLE hf;
	WIN32_FIND_DATA wfd;
	char st[512];

	_snprintf(st, sizeof(st), "%s*.*", path);
	//printf("DEBUG: find %s\n", st);
	hf = FindFirstFile(st, &wfd);

	while(hf != INVALID_HANDLE_VALUE)
	{
		if(strcmp(wfd.cFileName, ".") && strcmp(wfd.cFileName, ".."))
		{
			if(wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
			{
				spc(nestlv * 2);
				printf("%s\\\n", wfd.cFileName);
				_snprintf(st, sizeof(st), "%s%s\\", path, wfd.cFileName);
				find_worker(nestlv + 1, st);
			}else
			{
				//printf("%s\n", wfd.cFileName);
			}
		}
		if(!FindNextFile(hf, &wfd))
		{
			FindClose(hf);
			hf = INVALID_HANDLE_VALUE;
		}
	}
}

void snip(char *dest, const char *src, int width)
{
	char *p;
	char pfn[512];

	strcpy(dest, src);

	if(strlen(src) < width)
	{
		return;
	}

	while((p = strrchr(dest, '\\')) - dest == strlen(dest) - 1)
	{
		*p = '\0';
	}

	/*
	puts("DEBUG");
	printf("dest1:%s\n", dest);
	puts("!!!");
	*/

	// XXX: no multibyte support
	p = strrchr(dest, '\\');
	strcpy(pfn, p + 1);
	*p = '\0';
	//printf("pfn:%s\n", pfn);
	for(; p = strrchr(dest, '\\'); )
	{
		*p = '\0';

		//printf("dest2  :%s\n", dest);
		strcat(dest, "\\...\\");
		strcat(dest, pfn);
		//printf("dest2' :%s\n", dest);
		if(strlen(dest) < width)
		{
			//puts("OK");
			return;
		}
		*p = '\0';

		/*
		printf("dest2'':%s\n", dest);
		printf("p      :");
		spc(p - dest);
		printf("^\n");
		printf("strrchr:%d\n", strrchr(p - 1, '\\'));
		printf("dest-1 :%s\n", p - 1);
		*/
	}

	strcpy(dest + width - 3, "...");

	//puts("???");
}

void chkrecursive(int nestlv, const char *path)
{
	HANDLE hf;
	WIN32_FIND_DATA wfd;
	char st[512];

	//spc(nestlv);
	if(QueryDirectoryJunction(path, st))
	{
		printf("%s\t%s\n", path, st);
	}else
	{
		// XXX: fixed width!
		snip(st, path, 79);
		fprintf(stderr, "%s\r%s\r", sspc(79), st);
		//Sleep(100);

		_snprintf(st, sizeof(st), "%s*.*", path);
		hf = FindFirstFile(st, &wfd);

		while(hf != INVALID_HANDLE_VALUE)
		{
			if(strcmp(wfd.cFileName, ".") && strcmp(wfd.cFileName, ".."))
			{
				if(wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
				{
					_snprintf(st, sizeof(st), "%s%s\\", path, wfd.cFileName);
					chkrecursive(nestlv + 1, st);
				}
			}
			if(!FindNextFile(hf, &wfd))
			{
				FindClose(hf);
				hf = INVALID_HANDLE_VALUE;
			}
		}
	}
}

int main(int argc, char *argv[])
{
	if(argc < 2)
	{
		chkrecursive(0, ".\\");
	} else
	{
		int i;
		for(i = 1; argv[i]; i++)
		{
			chkrecursive(0, argv[i]);
		}
	}
	// XXX: fixed width!
	fprintf(stderr, "%s\r", sspc(79));

	return 0;
}
