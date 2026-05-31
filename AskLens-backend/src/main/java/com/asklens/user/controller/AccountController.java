package com.asklens.user.controller;

import com.asklens.auth.CurrentUserService;
import com.asklens.common.api.ApiResponse;
import com.asklens.common.log.OperationLog;
import com.asklens.user.model.dto.ChangePasswordRequest;
import com.asklens.user.service.AccountService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 个人账户控制器，提供修改密码等接口。
 */
@OperationLog
@RestController
@RequestMapping("/api/account")
public class AccountController {

    private final AccountService accountService;
    private final CurrentUserService currentUserService;

    public AccountController(AccountService accountService, CurrentUserService currentUserService) {
        this.accountService = accountService;
        this.currentUserService = currentUserService;
    }

    /** 修改当前登录用户的密码 */
    @PostMapping("/change-password")
    public ApiResponse<Void> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        accountService.changePassword(currentUserService.getRequiredCurrentUser(), request);
        return ApiResponse.success(null);
    }
}
